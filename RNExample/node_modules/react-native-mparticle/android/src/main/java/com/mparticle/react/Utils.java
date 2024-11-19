package com.mparticle.react;

import com.facebook.react.bridge.ReadableMap;

public class Utils {

    public static long parseMpid(String longString) {
        try {
            return Long.parseLong(longString);
        } catch (NumberFormatException ex) {
            return 0L;
        }
    }

    public static Long getLong(ReadableMap readableMap, String key, boolean allowLossy) {
        switch (readableMap.getType(key)) {
            case String:
                return Long.valueOf(readableMap.getString(key));
            case Number:
                if (allowLossy) {
                    try {
                        return Integer.valueOf(readableMap.getInt(key)).longValue();
                    } catch (Exception ex) {
                        return Double.valueOf(readableMap.getDouble(key)).longValue();
                    }
                }
                break;
            case Null:
                return null;
        }
        throw new NumberFormatException("Expecting " + (allowLossy ? " Number or " : "") + "String representation of a Long. Received " + readableMap.getType(key));
    }

}
