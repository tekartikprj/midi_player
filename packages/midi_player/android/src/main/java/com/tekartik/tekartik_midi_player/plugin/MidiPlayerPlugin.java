package com.tekartik.tekartik_midi_player.plugin;

import static com.tekartik.tekartik_midi_player.plugin.Constant.LOG_TAG;
import static com.tekartik.tekartik_midi_player.plugin.Constant.METHOD_CLOSE;
import static com.tekartik.tekartik_midi_player.plugin.Constant.METHOD_CURRENT_POSITION;
import static com.tekartik.tekartik_midi_player.plugin.Constant.METHOD_DEBUG_MODE;
import static com.tekartik.tekartik_midi_player.plugin.Constant.METHOD_DURATION;
import static com.tekartik.tekartik_midi_player.plugin.Constant.METHOD_GET_PLATFORM_VERSION;
import static com.tekartik.tekartik_midi_player.plugin.Constant.METHOD_LOAD_FILE;
import static com.tekartik.tekartik_midi_player.plugin.Constant.METHOD_ON_COMPLETE;
import static com.tekartik.tekartik_midi_player.plugin.Constant.METHOD_PAUSE;
import static com.tekartik.tekartik_midi_player.plugin.Constant.METHOD_PLAYING;
import static com.tekartik.tekartik_midi_player.plugin.Constant.METHOD_RESUME;
import static com.tekartik.tekartik_midi_player.plugin.Constant.METHOD_SEEK;
import static com.tekartik.tekartik_midi_player.plugin.Constant.PARAM_ID;
import static com.tekartik.tekartik_midi_player.plugin.Constant.PARAM_MILLIS;
import static com.tekartik.tekartik_midi_player.plugin.Constant.PARAM_PATH;
import static com.tekartik.tekartik_midi_player.plugin.Constant.PARAM_PLAYING;
import static com.tekartik.tekartik_midi_player.plugin.dev.Debug.LOGV;

import android.content.Context;
import android.media.MediaPlayer;
import android.util.Log;

import androidx.annotation.NonNull;

import com.tekartik.tekartik_midi_player.player.Player;

import java.io.File;
import java.util.HashMap;
import java.util.Map;

import io.flutter.embedding.engine.plugins.FlutterPlugin;
import io.flutter.plugin.common.BinaryMessenger;
import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;
import io.flutter.plugin.common.MethodChannel.MethodCallHandler;
import io.flutter.plugin.common.MethodChannel.Result;

/**
 * MidiPlayerPlugin
 */
public class MidiPlayerPlugin implements FlutterPlugin, MethodCallHandler {
    private MethodChannel channel;
    private Context context;

    final Map<Long, Player> players = new HashMap<>();

    public MidiPlayerPlugin() {

    }

    private void onAttached(Context context, BinaryMessenger messenger) {
        this.context = context;
        channel = new MethodChannel(messenger, Constant.PLUGIN_NAME);
        channel.setMethodCallHandler(this);
    }

    Long getPlayerId(Query query) {
        return query.longArgument(PARAM_ID);
    }

    Player getExistingPlayerOrError(Query query) {
        Long playerId = getPlayerId(query);
        if (playerId != null) {
            Player player = players.get(playerId);
            if (player != null) {
                return player;
            }
        }
        query.error(query.method, "no player", playerId);
        return null;
    }


    Player getPlayer(Query query) {
        Long playerId = getPlayerId(query);
        if (playerId != null) {
            Player player = players.get(playerId);
            if (player == null) {
                synchronized (this) {
                    player = players.get(playerId);
                    if (player == null) {
                        player = new Player(playerId);
                        players.put(playerId, player);
                    }
                }
            }
            if (LOGV) {
                Log.d(LOG_TAG, "getPlayer(" + playerId + ") " + player);
            }
            return player;
        }
        return null;
    }

    private void onResume(final Query query) {
        Player player = getExistingPlayerOrError(query);
        if (player != null) {
            player.resume();
            query.success(true);
        }
    }

    private void onPause(final Query query) {
        Player player = getExistingPlayerOrError(query);
        if (player != null) {
            player.pause();
            query.success(true);
        }
    }

    private void onSeek(final Query query) {
        Player player = getExistingPlayerOrError(query);
        if (player != null) {
            int millis = query.intArgument(PARAM_MILLIS);
            player.seekTo(millis, new MediaPlayer.OnSeekCompleteListener() {
                @Override
                public void onSeekComplete(MediaPlayer mp) {
                    query.success(true);
                }
            });
        }
    }

    private void onCurrentPosition(final Query query) {
        Player player = getExistingPlayerOrError(query);
        if (player != null) {
            Map<String, Object> map = new HashMap<>();
            map.put(PARAM_MILLIS, player.getCurrentPosition());
            query.success(map);
        }
    }

    private void onDuration(final Query query) {
        Player player = getExistingPlayerOrError(query);
        if (player != null) {
            Map<String, Object> map = new HashMap<>();
            map.put(PARAM_MILLIS, player.getDuration());
            query.success(map);
        }
    }

    private void onPlaying(final Query query) {
        Player player = getExistingPlayerOrError(query);
        if (player != null) {
            Map<String, Object> map = new HashMap<>();
            map.put(PARAM_PLAYING, player.isPlaying());
            query.success(map);
        }
    }

    private void onClose(final Query query) {
        Player player = getExistingPlayerOrError(query);
        if (player != null) {
            players.remove(player.getId());
            player.release();
            query.success(true);
        }
    }

    //
    // Load and prepare a file
    //
    private void onLoadFile(final Query query) {
        String path = query.argument(PARAM_PATH);
        final Player player = getPlayer(query);

        if (player.prepareFile(new File(path), new MediaPlayer.OnPreparedListener() {
            @Override
            public void onPrepared(MediaPlayer mp) {
                if (LOGV) {
                    Log.d(LOG_TAG, "onPrepared");
                }
                query.success(true);
            }
        }, new MediaPlayer.OnCompletionListener() {
            @Override
            public void onCompletion(MediaPlayer mp) {
                if (LOGV) {
                    Log.d(LOG_TAG, "onComplete!");
                }
                Map<String, Object> map = new HashMap<>();
                map.put(Constant.PARAM_ID, player.getId());
                channel.invokeMethod(METHOD_ON_COMPLETE, map);
            }
        }, new MediaPlayer.OnSeekCompleteListener() {
            @Override
            public void onSeekComplete(MediaPlayer mp) {
                if (LOGV) {
                    Log.d(LOG_TAG, "onSeekComplete");
                }
            }
        })) {
            //query.success(null);
        } else {
            query.error("error", "prepareFile failed", path);
        }
    }

    @Override
    public void onMethodCall(MethodCall call, Result result) {
        Query query = new Query(call, result);

        switch (query.method) {
            // quick testing
            case METHOD_GET_PLATFORM_VERSION:
                result.success("Android " + android.os.Build.VERSION.RELEASE);
                break;

            case METHOD_DEBUG_MODE: {
                Object on = call.arguments();
                LOGV = Boolean.TRUE.equals(on);
                result.success(null);
                break;
            }
            case METHOD_LOAD_FILE:
                onLoadFile(query);
                break;
            case METHOD_RESUME:
                onResume(query);
                break;
            case METHOD_PAUSE:
                onPause(query);
                break;
            case METHOD_CLOSE:
                onClose(query);
                break;
            case METHOD_SEEK:
                onSeek(query);
                break;
            case METHOD_CURRENT_POSITION:
                onCurrentPosition(query);
                break;
            case METHOD_DURATION:
                onDuration(query);
                break;
            case METHOD_PLAYING:
                onPlaying(query);
                break;

            default:
                result.notImplemented();
        }
    }

    @Override
    public void onAttachedToEngine(@NonNull FlutterPluginBinding binding) {
        MidiPlayerPlugin instance = new MidiPlayerPlugin();
        instance.onAttached(binding.getApplicationContext(), binding.getBinaryMessenger());
    }

    @Override
    public void onDetachedFromEngine(@NonNull FlutterPluginBinding binding) {
        channel.setMethodCallHandler(null);
        channel = null;
    }
}
