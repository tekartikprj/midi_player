package com.tekartik.tekartik_midi_player.plugin;

import android.util.Log;

import com.tekartik.tekartik_midi_player.plugin.dev.Debug;

import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;

import static com.tekartik.tekartik_midi_player.plugin.Constant.LOG_TAG;

public class Query implements MethodChannel.Result {
    final public String method;
    final private MethodCall methodCall;
    final private MethodChannel.Result result;

    public Query(MethodCall methodCall, MethodChannel.Result result) {
        this.methodCall = methodCall;
        this.result = result;
        method = methodCall.method;
        if (Debug.LOGV) {
            Log.d(LOG_TAG, "method " + method + " param " + arguments());
        }
    }

    public Long longArgument(String name) {
        Object param = argument(name);
        if (param instanceof  Long) {
            return (Long) param;
        } else if (param instanceof Integer) {
            return ((Integer)param).longValue();
        }
        return null;
    }

    public Integer intArgument(String name) {
        Object param = argument(name);
        if (param instanceof  Integer) {
            return (Integer) param;
        } else if (param instanceof Long) {
            return ((Long)param).intValue();
        }
        return null;
    }

    public <T> T argument(String name) {
        return methodCall.argument(name);
    }

    @Override
    public void success(Object o) {
        if (Debug.LOGV) {
            Log.d(LOG_TAG, "success: " + o);
        }

        result.success(o);
    }

    @Override
    public void error(String s, String s1, Object o) {
        if (Debug.LOGV) {
            Log.e(LOG_TAG, "error: " + s + " / " + s1 + "/ o");
        }
        result.error(s, s1, o);
    }

    @Override
    public void notImplemented() {
        result.notImplemented();
    }

    public <T> T arguments() {
        return methodCall.arguments();
    }
}
