const { onDocumentCreated } = require("firebase-functions/v2/firestore");
const { initializeApp } = require("firebase-admin/app");
const { getMessaging } = require("firebase-admin/messaging");

initializeApp();

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

    // Skip if required fields are missing
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

    console.log(
      `Sending notification to topic: farmer_${farmerId}`
    );

    try {
      const response = await getMessaging().send(payload);

      console.log(
        "Notification sent successfully:",
        response
      );

      return response;

    } catch (error) {
      console.error(
        "Error sending notification:",
        error
      );

      return null;
    }
  }
);