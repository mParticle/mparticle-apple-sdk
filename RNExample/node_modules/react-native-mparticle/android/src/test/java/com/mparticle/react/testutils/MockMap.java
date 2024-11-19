package com.mparticle.react.testutils;

import com.facebook.react.bridge.ReadableArray;
import com.facebook.react.bridge.ReadableMap;
import com.facebook.react.bridge.ReadableMapKeySetIterator;
import com.facebook.react.bridge.ReadableType;
import com.facebook.react.bridge.WritableArray;
import com.facebook.react.bridge.WritableMap;

import org.json.JSONException;
import org.json.JSONObject;

import java.util.ArrayList;
import java.util.Collection;
import java.util.HashMap;
import java.util.Iterator;
import java.util.List;
import java.util.Map;

public class MockMap implements WritableMap {
    private Map map = new HashMap();

    public MockMap() {}

    public MockMap(JSONObject jsonObject) throws JSONException {
        Map map = new HashMap();
        Iterator<String> keys = jsonObject.keys();
        while(keys.hasNext()) {
            String key = keys.next();
            map.put(key, jsonObject.get(key));
        }
        this.map = map;
    }

    public MockMap(Map map) {
        this.map = map;
    }

    @Override
    public boolean hasKey(String name) {
        return map.containsKey(name);
    }

    @Override
    public boolean isNull(String name) {
        return map.get(name) == null;
    }

    @Override
    public boolean getBoolean(String name) {
        return (boolean) map.get(name);
    }

    @Override
    public double getDouble(String name) {
        return (double) map.get(name);
    }

    @Override
    public int getInt(String name) {
        return (int) map.get(name);
    }

    @Override
    public String getString(String name) {
        return (String) map.get(name);
    }

    @Override
    public ReadableArray getArray(String name) {
        return null;
    }

    @Override
    public ReadableMap getMap(String name) {
        return new MockMap((Map) map.get(name));
    }

    @Override
    public ReadableType getType(String name) {
        Object obj = map.get(name);
        if (obj instanceof String) {
            return ReadableType.String;
        }
        if (obj instanceof Number) {
            return ReadableType.Number;
        }
        if (obj instanceof Collection) {
            return ReadableType.Array;
        }
        if (obj instanceof Map) {
            return ReadableType.Map;
        }
        if (obj instanceof Boolean) {
            return ReadableType.Boolean;
        }
        if (obj == null) {
            return ReadableType.Null;
        }
        return null;
    }

    @Override
    public ReadableMapKeySetIterator keySetIterator() {
        return new MockReadableMapKeySetIterator(map.keySet());
    }

    @Override
    public void putNull(String key) {
        map.put(key, null);
    }

    @Override
    public void putBoolean(String key, boolean value) {
        map.put(key, value);
    }

    @Override
    public void putDouble(String key, double value) {
        map.put(key, value);
    }

    @Override
    public void putInt(String key, int value) {
        map.put(key, value);
    }

    @Override
    public void putString(String key, String value) {
        map.put(key, value);
    }

    @Override
    public void putArray(String key, WritableArray value) {
        map.put(key, value);
    }

    @Override
    public void putMap(String key, WritableMap value) {
        map.put(key, value);
    }

    @Override
    public void merge(ReadableMap source) {
        throw new RuntimeException("Not Implemented");
    }


    class MockReadableMapKeySetIterator implements ReadableMapKeySetIterator {
        List<String> keys;
        int index = 0;

        MockReadableMapKeySetIterator(Collection<String> keys) {
            this.keys = new ArrayList(keys);
        }

        @Override
        public boolean hasNextKey() {
            return index < keys.size();
        }

        @Override
        public String nextKey() {
            String val = keys.get(index);
            index++;
            return val;
        }
    }
}