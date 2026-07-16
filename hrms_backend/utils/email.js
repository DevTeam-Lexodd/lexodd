
const { ClientSecretCredential } = require("@azure/identity");
const fetch = require("isomorphic-fetch");
const crypto = require("crypto");
require("dotenv").config({ path: ".env" });
const fs = require("fs");
const path = require("path");
const PaymentConfig = require("../models/paymentConfigModel");


const logoPath = path.join(__dirname, "../images/logo.png");

// --- Azure AD App Credentials & Sender ---
const tenantId = process.env.AZURE_TENANT_ID;
const clientId = process.env.AZURE_CLIENT_ID;
const clientSecret = process.env.AZURE_CLIENT_SECRET;
const senderEmail = process.env.EMAIL_USER; // the mailbox that will send via Graph
  
// Create credential once
const credential = new ClientSecretCredential(tenantId, clientId, clientSecret);

// --- Shared helper: send mail through Microsoft Graph with inline logo ---
// --- Centralized email sender with quota & error handling ---

async function sendEmail({ to, subject, html }) {
  const recipientEmail =
    typeof to === "string" ? to : to?.email || String(to || "");

  if (!recipientEmail) {
    console.error("❌ Email sending failed: Missing recipient.");
    return { success: false, reason: "MISSING_RECIPIENT" };
  }

  try {
    console.log("📨 Preparing email...");
    console.log("Sender:", senderEmail);
    console.log("Recipient:", recipientEmail);

    const tokenResponse = await credential.getToken(
      "https://graph.microsoft.com/.default"
    );

    if (!tokenResponse || !tokenResponse.token) {
      console.error("❌ Failed to get Microsoft Graph token");
      return { success: false, reason: "TOKEN_ERROR" };
    }

    const logoContentBytes = fs.readFileSync(logoPath).toString("base64");

    const payload = {
      message: {
        subject,
        body: {
          contentType: "HTML",
          content: html,
        },
        toRecipients: [
          {
            emailAddress: {
              address: recipientEmail,
            },
          },
        ],
        attachments: [
          {
            "@odata.type": "#microsoft.graph.fileAttachment",
            name: "logo.png",
            contentId: "unique-logo-cid",
            isInline: true,
            contentBytes: logoContentBytes,
          },
        ],
      },
      saveToSentItems: true,
    };

    const controller = new AbortController();
    const timeout = setTimeout(() => controller.abort(), 15000);

    let res;

    try {
      res = await fetch(
        `https://graph.microsoft.com/v1.0/users/${encodeURIComponent(
          senderEmail
        )}/sendMail`,
        {
          method: "POST",
          headers: {
            Authorization: `Bearer ${tokenResponse.token}`,
            "Content-Type": "application/json",
          },
          body: JSON.stringify(payload),
          signal: controller.signal,
        }
      );
    } catch (networkError) {
      console.error("❌ Network error while sending email:", networkError.message);
      return { success: false, reason: "NETWORK_ERROR", details: networkError.message };
    }

    clearTimeout(timeout);

    if (!res.ok) {
      const text = await res.text().catch(() => "");

      console.error("❌ Graph API error:", {
        status: res.status,
        body: text,
      });

      return {
        success: false,
        reason: `GRAPH_ERROR_${res.status}`,
        details: text,
      };
    }

    console.log("✅ Email sent successfully to:", recipientEmail);

    return { success: true };
  } catch (error) {
  const errorMessage = error.message || "";

  console.error("❌ Unexpected email send error:", errorMessage);

  // 🔴 INVALID CLIENT SECRET (YOUR CASE)
  if (errorMessage.includes("AADSTS7000215")) {
    return {
      success: false,
      reason: "INVALID_AZURE_CLIENT_SECRET",
      details:
        "The Azure client secret is invalid or expired. Use the SECRET VALUE (not ID) from Azure Portal.",
    };
  }

  // 🔴 INVALID CLIENT ID
  if (errorMessage.includes("AADSTS700016")) {
    return {
      success: false,
      reason: "INVALID_CLIENT_ID",
      details: "Azure Client ID is incorrect or app not found.",
    };
  }

  // 🔴 TENANT ISSUE
  if (errorMessage.includes("AADSTS500011")) {
    return {
      success: false,
      reason: "INVALID_TENANT",
      details: "Azure Tenant ID is incorrect.",
    };
  }

  // 🔴 NETWORK / TIMEOUT
  if (error.name === "AbortError") {
    return {
      success: false,
      reason: "TIMEOUT",
      details: "Email request timed out.",
    };
  }

  // 🔴 FALLBACK
  return {
    success: false,
    reason: "UNKNOWN_ERROR",
    details: errorMessage,
  };
}
}