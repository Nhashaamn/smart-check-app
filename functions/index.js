const { onDocumentCreated } = require('firebase-functions/v2/firestore');
const { initializeApp } = require('firebase-admin/app');
const { getFirestore } = require('firebase-admin/firestore');
const { getMessaging } = require('firebase-admin/messaging');

// Initialize Firebase Admin
initializeApp();

// Define the Cloud Function using Functions v2
exports.sendFingerprintAuthNotification = onDocumentCreated(
  'notifications_trigger/{docId}',
  async (event) => {
    const snap = event.data;
    const data = snap.data();

    if (data.type !== 'fingerprint_auth') return;

    const taskId = data.taskId;
    const teamDocId = data.teamDocId;
    const memberName = data.memberName;
    const adminUid = data.adminUid;

    // Get the admin's FCM token
    const adminDoc = await getFirestore()
      .collection('users')
      .doc(adminUid)
      .get();
    if (!adminDoc.exists || !adminDoc.data().fcmToken) {
      console.log('Admin or FCM token not found');
      return;
    }
    const adminFcmToken = adminDoc.data().fcmToken;

    // Construct the notification payload
    const payload = {
      notification: {
        title: 'Fingerprint Authentication',
        body: `${memberName} has authenticated for task ${taskId} at 11:08 PM PKT on Tuesday, May 13, 2025`,
      },
      data: {
        click_action: 'FLUTTER_NOTIFICATION_CLICK',
        taskId: taskId,
        teamDocId: teamDocId,
      },
      token: adminFcmToken,
    };

    // Set high priority for delivery even when screen is off
    const androidConfig = {
      priority: 'high',
      notification: {
        channelId: 'fingerprint_auth_channel',
      },
    };

    const apnsConfig = {
      headers: {
        'apns-priority': '10',
      },
      payload: {
        aps: {
          contentAvailable: true,
        },
      },
    };

    try {
      await getMessaging().send({
        ...payload,
        android: androidConfig,
        apns: apnsConfig,
      });
      console.log('Successfully sent notification to admin');
      // Delete the trigger document after sending
      await snap.ref.delete();
    } catch (error) {
      console.error('Error sending notification:', error);
      throw new Error('Failed to send notification');
    }
  }
);