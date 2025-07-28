var exec = require("cordova/exec");

var DndCheck = {
    isDndEnabled: function(successCallback, errorCallback) {
        console.log("[DndCheck] Calling native isDndEnabled...");
        exec(
            function(result) {
                // Convert integer result (1/0) to boolean
                const isDndEnabled = result === 1;
                console.log("[DndCheck] Native result:", result, "converted to:", isDndEnabled);
                successCallback(isDndEnabled);
            }, 
            function(error) {
                console.error("[DndCheck] Native plugin error:", error);
                errorCallback(error);
            }, 
            "DndCheck", 
            "isDndEnabled", 
            []
        );
    }
};

module.exports = DndCheck; 