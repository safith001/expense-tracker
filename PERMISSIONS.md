# Native Permissions Matrix

## 1. Android Manifest Permissions (`android/app/src/main/AndroidManifest.xml`)

| Permission Name | Technical Descriptor | Justification |
|---|---|---|
| **INTERNET** | `android.permission.INTERNET` | Required for sending month-end JSON payloads to the Google Apps Script Web App endpoint. |
| **ACCESS_NETWORK_STATE** | `android.permission.ACCESS_NETWORK_STATE` | Required by `WorkManager` constraints to ensure the device is connected before triggering sync operations. |
| **RECEIVE_BOOT_COMPLETED** | `android.permission.RECEIVE_BOOT_COMPLETED` | Allows `WorkManager` to reschedule the month-end background worker if the phone is rebooted. |

## 2. Implementation Configuration

Add the following tags directly within the `<manifest>` block in `android/app/src/main/AndroidManifest.xml`:

```xml
<manifest xmlns:android="[http://schemas.android.com/apk/res/android](http://schemas.android.com/apk/res/android)">
    <!-- Network Access for Google Sheets Sync -->
    <uses-permission android:name="android.permission.INTERNET" />
    <uses-permission android:name="android.permission.ACCESS_NETWORK_STATE" />
    
    <!-- Auto-reschedule Background Worker on Device Reboot -->
    <uses-permission android:name="android.permission.RECEIVE_BOOT_COMPLETED" />

    <application
        android:label="MedExpense"
        android:name="${applicationName}"
        android:icon="@mipmap/ic_launcher">
        ...
    </application>
</manifest>