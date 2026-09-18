// paystackService.js
// Wrapper for Paystack API calls used in the Marketplace project.
// Reads Paystack values from environment variables.

const axios = require('axios');

const PAYSTACK_SECRET = process.env.PAYSTACK_SECRET_KEY;
const PAYSTACK_PUBLIC = process.env.PAYSTACK_PUBLIC_KEY;
const PAYSTACK_CALLBACK_URL = process.env.PAYSTACK_CALLBACK_URL || '';
const PAYSTACK_BASE_URL = 'https://api.paystack.co';

/**
 * Initialize a Paystack transaction for a buyer.
 * @param {string} email - Buyer's email address.
 * @param {number} amountKobo - Amount in kobo (NGN * 100).
 * @param {string} reference - Unique reference for the transaction (order ID).
 * @returns {Promise<string>} Paystack authorization URL.
 */
async function initializeTransaction(email, amountKobo, reference) {
  const payload = {
    email,
    amount: amountKobo,
    reference,
    callback_url: PAYSTACK_CALLBACK_URL, // optional
  };
  const response = await axios.post(
    `${PAYSTACK_BASE_URL}/transaction/initialize`,
    payload,
    {
      headers: {
        Authorization: `Bearer ${PAYSTACK_SECRET}`,
        'Content-Type': 'application/json',
      },
    }
  );
  if (response.data && response.data.status) {
    return response.data.data.authorization_url;
  }
  throw new Error('Paystack initialization failed');
}

/**
 * Verify a Paystack transaction.
 * @param {string} reference - Transaction reference.
 * @returns {Promise<object>} Verification result from Paystack.
 */
async function verifyTransaction(reference) {
  const response = await axios.get(
    `${PAYSTACK_BASE_URL}/transaction/verify/${reference}`,
    {
      headers: { Authorization: `Bearer ${PAYSTACK_SECRET}` },
    }
  );
  if (response.data && response.data.status) {
    return response.data.data;
  }
  throw new Error('Paystack verification failed');
}

/**
 * Initiate a Paystack transfer (admin pays farmer).
 * @param {string} recipientCode - Paystack recipient code for the farmer.
 * @param {number} amountKobo - Amount in kobo.
 * @param {string} reference - Unique reference for the transfer.
 * @returns {Promise<object>} Transfer response.
 */
async function createTransfer(recipientCode, amountKobo, reference) {
  const payload = {
    source: 'balance',
    amount: amountKobo,
    recipient: recipientCode,
    reference,
  };
  const response = await axios.post(
    `${PAYSTACK_BASE_URL}/transfer`,
    payload,
    {
      headers: {
        Authorization: `Bearer ${PAYSTACK_SECRET}`,
        'Content-Type': 'application/json',
      },
    }
  );
  if (response.data && response.data.status) {
    return response.data.data;
  }
  throw new Error('Paystack transfer failed');
}

module.exports = {
  initializeTransaction,
  verifyTransaction,
  createTransfer,
  PAYSTACK_PUBLIC,
};
