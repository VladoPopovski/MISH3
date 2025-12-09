/**
 * Import function triggers from their respective submodules:
 *
 * const {onCall} = require("firebase-functions/v2/https");
 * const {onDocumentWritten} = require("firebase-functions/v2/firestore");
 *
 * See a full list of supported triggers at https://firebase.google.com/docs/functions
 */

const {setGlobalOptions} = require("firebase-functions");
const {onRequest} = require("firebase-functions/https");
const logger = require("firebase-functions/logger");

// For cost control, you can set the maximum number of containers that can be
// running at the same time. This helps mitigate the impact of unexpected
// traffic spikes by instead downgrading performance. This limit is a
// per-function limit. You can override the limit for each function using the
// `maxInstances` option in the function's options, e.g.
// `onRequest({ maxInstances: 5 }, (req, res) => { ... })`.
// NOTE: setGlobalOptions does not apply to functions using the v1 API. V1
// functions should each use functions.runWith({ maxInstances: 10 }) instead.
// In the v1 API, each function can only serve one request per container, so
// this will be the maximum concurrent request count.
setGlobalOptions({ maxInstances: 10 });

// Create and deploy your first functions
// https://firebase.google.com/docs/functions/get-started

// exports.helloWorld = onRequest((request, response) => {
//   logger.info("Hello logs!", {structuredData: true});
//   response.send("Hello from Firebase!");
// });
////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////
const functions = require("firebase-functions");
const admin = require("firebase-admin");
admin.initializeApp();

exports.sendDailyRecipeNotification = functions.pubsub
  .schedule("22 04 * * *") // 10:00 every day
  .timeZone("Europe/Skopje")
  .onRun(async (context) => {
    console.log("Running daily recipe notification job");

    // Read all device tokens from Firestore
    const snapshot = await admin.firestore()
      .collection("fcm_tokens")
      .get();

    if (snapshot.empty) {
      console.log("No tokens found");
      return null;
    }

    const tokens = snapshot.docs.map(doc => doc.id);

    const payload = {
      notification: {
        title: "Recipe of the Day",
        body: "Open the app to see today's random meal!"
      }
    };

    try {
      const response = await admin.messaging().sendToDevice(tokens, payload);
      console.log("Notification sent:", response.successCount, "success");
    } catch (error) {
      console.error("Error sending notification:", error);
    }

    return null;
  });

