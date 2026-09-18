// functions/index.js
// Firebase Functions entry point. Includes existing Firestore trigger and new Express API.

const functions = require('firebase-functions');
const admin = require('firebase-admin');
const express = require('express');
const cors = require('cors');
const { onDocumentCreated } = require('firebase-functions/v2/firestore');
const { getMessaging } = require('firebase-admin/messaging');
const { initializeApp } = require('firebase-admin/app');
const { initializeTransaction, createTransfer } = require('./paystackService');

const PAYSTACK_WEBHOOK_SECRET = process.env.PAYSTACK_WEBHOOK_SECRET;

initializeApp();

// --------- Existing Firestore trigger ---------
exports.notifyNewProduct = onDocumentCreated(
  "products/{productId}",
  async (event) => {
    const snap = event.data;
    if (!snap) {
      console.log("No document data found");
      return null;
    }
    const product = snap.data();
    const farmerId = product.farmerId;
    const farmerName = product.farmerName || "Farmer";
    const productName = product.name;
    if (!farmerId || !productName) {
      console.log("Missing farmerId or productName");
      return null;
    }
    const payload = {
      notification: {
        title: "New Product Available!",
        body: `${farmerName} has listed ${productName}.`,
      },
      data: {
        productId: event.params.productId,
        click_action: "FLUTTER_NOTIFICATION_CLICK",
      },
      topic: `farmer_${farmerId}`,
    };
    try {
      const response = await getMessaging().send(payload);
      console.log(`Notification sent to farmer_${farmerId}`);
      return response;
    } catch (error) {
      console.error("Error sending notification:", error);
      return null;
    }
  }
);

exports.sendNotificationOutbox = onDocumentCreated(
  "notificationOutbox/{notificationId}",
  async (event) => {
    const snap = event.data;
    if (!snap) return null;

    const notification = snap.data();
    const userId = notification.targetUserId;
    if (!userId) return null;

    try {
      const userSnapshot = await admin
        .firestore()
        .collection('users')
        .doc(userId)
        .get();
      const tokens = userSnapshot.exists
          ? userSnapshot.data().fcmTokens || []
          : [];
      if (tokens.length > 0) {
        await getMessaging().sendEachForMulticast({
          tokens,
          notification: {
            title: notification.title,
            body: notification.body,
          },
          data: Object.fromEntries(
            Object.entries({
              ...(notification.data || {}),
              type: notification.type || 'general',
            }).map(([key, value]) => [key, String(value)])
          ),
        });
      }
      await snap.ref.update({ status: 'sent', sentAt: admin.firestore.FieldValue.serverTimestamp() });
    } catch (error) {
      console.error('Error sending notification outbox item:', error);
      await snap.ref.update({ status: 'failed', error: String(error) });
    }
    return null;
  }
);

// --------- Express API for payment workflow ---------
const app = express();
app.use(cors({ origin: true }));
app.use(express.json());

// Helper to extract order from Firestore (placeholder implementation)
const db = admin.firestore();
async function getOrder(orderId) {
  const doc = await db.collection('orders').doc(orderId).get();
  if (!doc.exists) throw new Error('Order not found');
  return { id: doc.id, ...doc.data() };
}

async function notifyUser(userId, title, body, type, data = {}) {
  const topic = `user_${userId}`;
  await db.collection('notifications').add({
    userId,
    topic,
    title,
    body,
    type,
    data,
    read: false,
    createdAt: admin.firestore.FieldValue.serverTimestamp(),
    createdAtMillis: Date.now(),
  });

  const userSnapshot = await db.collection('users').doc(userId).get();
  const tokens = userSnapshot.exists ? userSnapshot.data().fcmTokens || [] : [];
  if (tokens.length > 0) {
    await getMessaging().sendEachForMulticast({
      tokens,
      notification: { title, body },
      data: Object.fromEntries(
        Object.entries({ ...data, type }).map(([key, value]) => [
          key,
          String(value),
        ])
      ),
    });
  }
}

// 1. Buyer creates transaction – returns Paystack URL
app.post('/createTransaction', async (req, res) => {
  const { orderId, amount, buyerEmail, orderIds } = req.body; // amount in NGN
  try {
    const order = await getOrder(orderId);
    if (order.orderStatus !== 'Accepted') {
      return res
        .status(409)
        .send('Payment is available only after the farmer approves the order.');
    }
    const reference = `order_${orderId}`;
    const url = await initializeTransaction(buyerEmail, amount * 100, reference);
    const paymentOrderIds = Array.isArray(orderIds) && orderIds.length > 0
      ? orderIds
      : [orderId];
    // Store reference in order
    await db.collection('orders').doc(orderId).update({
      paystackReference: reference,
      paymentStatus: 'pending',
      paymentOrderIds,
    });
    res.json({ authorizationUrl: url });
  } catch (e) {
    console.error(e);
    res.status(500).send(e.message);
  }
});

// 2. Farmer accepts order
app.post('/farmer/accept', async (req, res) => {
  const { orderId, farmerId } = req.body;
  try {
    const order = await getOrder(orderId);
    if (order.farmerId !== farmerId) throw new Error('Farmer mismatch');
    await db.collection('orders').doc(orderId).update({ farmerAccepted: true });
    // Notify admin (could be a pub/sub, omitted for brevity)
    res.send('Order accepted');
  } catch (e) {
    console.error(e);
    res.status(400).send(e.message);
  }
});

// 3. Admin requests payout to farmer (after payment received)
app.post('/admin/payout', async (req, res) => {
  const { orderId, recipientCode, amount } = req.body; // amount in NGN
  try {
    const order = await getOrder(orderId);
    if (order.paymentStatus !== 'success') throw new Error('Payment not completed');
    const reference = `payout_${orderId}`;
    const transfer = await createTransfer(recipientCode, amount * 100, reference);
    await db.collection('orders').doc(orderId).update({
      payoutReference: reference,
      payoutStatus: 'in_progress',
    });
    res.json({ transfer });
  } catch (e) {
    console.error(e);
    res.status(500).send(e.message);
  }
});

// 4. Paystack webhook for buyer transaction verification
app.post('/paystack/webhook/buyer', async (req, res) => {
  const signature = req.headers['x-paystack-signature'];
  const crypto = require('crypto');
  const hash = crypto.createHmac('sha512', PAYSTACK_WEBHOOK_SECRET).update(JSON.stringify(req.body)).digest('hex');
  if (hash !== signature) {
    return res.status(400).send('Invalid signature');
  }
  const event = req.body;
  if (event.event === 'charge.success') {
    const reference = event.data.reference;
    const orderId = reference.replace('order_', '');
    const paidOrderRef = db.collection('orders').doc(orderId);
    const paidOrderSnap = await paidOrderRef.get();
    const paidOrder = paidOrderSnap.exists ? paidOrderSnap.data() : null;
    const paymentUpdate = {
      orderStatus: 'Paid',
      paymentStatus: 'success',
      paymentReceived: true,
    };

    const paymentOrderIds = Array.isArray(paidOrder?.paymentOrderIds)
      ? paidOrder.paymentOrderIds
      : [orderId];
    const paymentOrders = await Promise.all(
      paymentOrderIds.map(async (paymentOrderId) => {
        const paymentOrderRef = db.collection('orders').doc(paymentOrderId);
        const paymentOrderSnap = await paymentOrderRef.get();
        return paymentOrderSnap.exists
          ? { ref: paymentOrderRef, data: paymentOrderSnap.data(), id: paymentOrderId }
          : null;
      })
    );
    const batch = db.batch();
    paymentOrders.filter(Boolean).forEach((paymentOrder) => {
      batch.update(paymentOrder.ref, paymentUpdate);
    });
    await batch.commit();
    await Promise.all(
      paymentOrders.filter(Boolean).map((paymentOrder) =>
        notifyUser(
          paymentOrder.data.farmerId,
          'Payment received',
          `${paymentOrder.data.productName || 'Your order'} has been paid for by the buyer.`,
          'payment_received',
          { orderId: paymentOrder.id }
        )
      )
    );
  }
  res.send('ok');
});

// 5. Paystack webhook for payout transfer status
app.post('/paystack/webhook/payout', async (req, res) => {
  const signature = req.headers['x-paystack-signature'];
  const crypto = require('crypto');
  const hash = crypto.createHmac('sha512', PAYSTACK_WEBHOOK_SECRET).update(JSON.stringify(req.body)).digest('hex');
  if (hash !== signature) return res.status(400).send('Invalid signature');
  const event = req.body;
  if (event.event === 'transfer.success' || event.event === 'transfer.failed') {
    const reference = event.data.reference;
    const orderId = reference.replace('payout_', '');
    await db.collection('orders').doc(orderId).update({
      payoutStatus: event.event === 'transfer.success' ? 'success' : 'failed',
    });
  }
  res.send('ok');
});

// Export the Express app as a Cloud Function
exports.api = functions.https.onRequest(app);
