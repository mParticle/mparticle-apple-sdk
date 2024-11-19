package com.mparticle.react.testutils;

import com.facebook.react.bridge.ReadableArray;
import com.facebook.react.bridge.ReadableMap;
import com.facebook.react.bridge.ReadableType;

public class MockReadableArray implements ReadableArray {

    @Override
    public int size() {
        return 0;
    }

    @Override
    public boolean isNull(int index) {
        return false;
    }

    @Override
    public boolean getBoolean(int index) {
        return false;
    }

    @Override
    public double getDouble(int index) {
        return 0;
    }

    @Override
    public int getInt(int index) {
        return 0;
    }

    @Override
    public String getString(int index) {
        return null;
    }

    @Override
    public ReadableArray getArray(int index) {
        return null;
    }

    @Override
    public ReadableMap getMap(int index) {
        return null;
    }

    @Override
    public ReadableType getType(int index) {
        return null;
    }
}