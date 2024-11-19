package com.mparticle.react.testutils;

public class Mutable<T> {
    public T value;

    public Mutable() {
        value = null;
    }

    public Mutable(T t) {
        this.value = t;
    }
}
