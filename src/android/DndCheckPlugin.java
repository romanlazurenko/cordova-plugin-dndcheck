package com.romanlazurenko.dndcheck;

import org.apache.cordova.CordovaPlugin;
import org.apache.cordova.CallbackContext;
import org.json.JSONArray;
import org.json.JSONException;

import android.content.Context;
import android.app.NotificationManager;
import android.os.Build;

public class DndCheckPlugin extends CordovaPlugin {

    @Override
    public boolean execute(String action, JSONArray args, CallbackContext callbackContext) throws JSONException {
        if (action.equals("isDndEnabled")) {
            this.isDndEnabled(callbackContext);
            return true;
        }
        return false;
    }

    private void isDndEnabled(CallbackContext callbackContext) {
        try {
            System.out.println("[DndCheckPlugin] isDndEnabled called from native code");
            
            Context context = this.cordova.getActivity().getApplicationContext();
            NotificationManager notificationManager = (NotificationManager) context.getSystemService(Context.NOTIFICATION_SERVICE);
            
            boolean isDndEnabled = false;
            
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                // For Android 6.0 (API level 23) and above
                int currentMode = notificationManager.getCurrentInterruptionFilter();
                
                // Based on observed values:
                // Mode 1 = DND disabled (normal notifications)
                // Mode 2 = DND enabled (no notifications)
                isDndEnabled = (currentMode == 2);
                
                System.out.println("[DndCheckPlugin] Android version >= M, current mode: " + currentMode + ", DND enabled: " + isDndEnabled);
            } else {
                // For older versions, we can't reliably check DND state
                // Return false to allow sound playback
                isDndEnabled = false;
                System.out.println("[DndCheckPlugin] Android version < M, returning false");
            }
            
            // Return integer (1 for true, 0 for false) since CallbackContext.success doesn't accept boolean
            int result = isDndEnabled ? 1 : 0;
            System.out.println("[DndCheckPlugin] Returning result: " + result);
            callbackContext.success(result);
        } catch (Exception e) {
            System.out.println("[DndCheckPlugin] Error: " + e.getMessage());
            callbackContext.error("Error checking DND state: " + e.getMessage());
        }
    }
} 