package com.tekartik.tekartik_midi_player.player;

import android.content.Context;
import android.media.MediaPlayer;
import android.media.MediaPlayer.OnCompletionListener;
import android.net.Uri;
import android.util.Log;

import java.io.File;
import java.io.FileDescriptor;
import java.io.FileInputStream;
import java.io.FileNotFoundException;
import java.io.FileOutputStream;
import java.io.IOException;
import java.util.ArrayList;
import java.util.HashSet;
import java.util.List;
import java.util.Set;

import static com.tekartik.tekartik_midi_player.plugin.dev.Debug.LOGV;

public class Player implements OnCompletionListener, MediaPlayer.OnPreparedListener, MediaPlayer.OnSeekCompleteListener {

    Context mContext;

    static final String TAG = "MdyPlayer";

    MediaPlayer mp;
    public boolean mediaStarted = false;
    public boolean mediaPrepared = false;
    public boolean mediaPaused = false;
    public boolean mediaCompleted = false;

    static final String TEMP_FILE_NAME = "temp.mid";

    static final int DELAY_SLOW = 240;
    static final int DELAY_FAST = 120;
    static final int DELAY_STRUM = 30;
    int delay;
    String mPlayerName;
    final Long id;

    OnCompletionListener mCompletionListener;

    public Player(Long playerId) {
        this.id = playerId;
    }

    java.io.File getTempFile() {
        return new java.io.File(mContext.getCacheDir(), mPlayerName + TEMP_FILE_NAME);
    }

    public Player(Context context, Long id, String name) {
        mContext = context.getApplicationContext();
        mPlayerName = name;
        this.id = id;
    }

    FileOutputStream getFileOutputStream() {
        FileOutputStream out;
        try {
            Log.v(TAG, "Writing file: "
                    + Uri.fromFile(getTempFile()).toString());
            out = new FileOutputStream(getTempFile());
        } catch (FileNotFoundException e) {
            // TODO Auto-generated catch block
            e.printStackTrace();
            return null;
        }
        return out;
    }

    FileInputStream getFileInputStream(File file) {
        FileInputStream in;
        try {
            in = new FileInputStream(file);
        } catch (FileNotFoundException e) {
            e.printStackTrace();
            return null;
        }
        return in;
    }

    FileInputStream getFileInputStream() {
        return getFileInputStream(getTempFile());
    }

    public boolean writeData(byte data[]) {
        FileOutputStream out = getFileOutputStream();
        if (out == null) {
            return false;
        }

        try {
            out.write(data);
            //new FileWriter(midiFile, out).writeFile();
        } catch (IOException e) {
            e.printStackTrace();
            return false;
        } finally {
            try {
                out.close();
            } catch (IOException e) {
                e.printStackTrace();
            }
        }
        return true;
    }


    public boolean prepare(byte data[], final MediaPlayer.OnPreparedListener onPreparedListener,
                           final OnCompletionListener completionListener,
                           final MediaPlayer.OnSeekCompleteListener onSeekCompleteListener) {
        writeData(data);
        return prepareFile(getTempFile(), onPreparedListener, completionListener, onSeekCompleteListener);
    }

    public boolean prepareFile(File file, final MediaPlayer.OnPreparedListener onPreparedListener,
                               final OnCompletionListener completionListener,
                               final MediaPlayer.OnSeekCompleteListener onSeekCompleteListener) {


        if (LOGV) {
            Log.d(TAG, "prepareFile player " + mp);
        }
        if (mp == null) {
            mp = new MediaPlayer();
        }

        FileInputStream fis = getFileInputStream(file);
        if (fis == null) {
            return false;
        }

        Log.v(TAG, "Opening file: "
                + Uri.fromFile(file).toString());
        // AssetFileDescriptor afd = App.getContext().getResources()
        // .openRawResourceFd(0);
        try {
            mp.setDataSource(fis.getFD()); // Uri.fromFile(tempFile).toString());
        } catch (IllegalArgumentException e) {
            e.printStackTrace();
            mp.release();
            return false;
        } catch (IllegalStateException e) {
            e.printStackTrace();
            release();
            return false;
        } catch (IOException e) {
            e.printStackTrace();
            release();
            return false;
        }
        // mp.setOnBufferingUpdateListener(this);
        // mp.setOnCompletionListener(this);
        // mp.setOnErrorListener(this);
        // mp.setOnPreparedListener(this);
        /*
        try {
            mp.prepare();
            // mp.setLooping(true);
            mediaPrepared = true;
        } catch (IllegalStateException e) {
            e.printStackTrace();
            release();
            return;
        } catch (IOException e) {
            e.printStackTrace();
            release();
            return;
        }
        if (mp == null) {
            mp = new MediaPlayer();
        }*/
        mp.setOnPreparedListener(new MediaPlayer.OnPreparedListener() {
            @Override
            public void onPrepared(MediaPlayer mp) {
                Player.this.onPrepared(mp);
                if (onPreparedListener != null) {
                    onPreparedListener.onPrepared(mp);
                }
            }
        });

        // Track update
        mp.setOnCompletionListener(new OnCompletionListener() {
            @Override
            public void onCompletion(MediaPlayer mp) {
                Player.this.onCompletion(mp);
                if (completionListener != null) {
                    completionListener.onCompletion(mp);
                }
            }
        });

        mp.setOnSeekCompleteListener(new MediaPlayer.OnSeekCompleteListener() {
            @Override
            public void onSeekComplete(MediaPlayer mp) {
                Player.this.onSeekComplete(mp);
                onSeekCompleteListener.onSeekComplete(mp);
            }
        });

        try {
            mp.prepareAsync();
        } catch (IllegalStateException e) {
            e.printStackTrace();
            release();
            return false;
        }
        return true;


        //mp.seekTo();
    }

    /*
    boolean writeTempFile(File midiFile) {

        FileOutputStream out = getFileOutputStream();
        if (out == null) {
            return false;
        }

        try {
            new FileWriter(midiFile, out).writeFile();
        } catch (MidiException e) {
            e.printStackTrace();
            return false;
        } finally {
            try {
                out.close();
            } catch (IOException e) {
                e.printStackTrace();
            }
        }
        return true;
    }
    */


    public FileDescriptor getFD() throws IOException {
        return getFileInputStream().getFD();
    }

    synchronized boolean prepare() {
        if (!mediaPrepared) {

            mp = new MediaPlayer();

            if (mp == null) {
                Log.v(TAG, String.format("new MediaPlayer() is null"));
                return false;
            }
            Log.v(TAG, String.format("Preparing %s", mp.toString()));
            // setData();
            // tempFile = new java.io.File(App.getContext().getCacheDir(),
            // "temp1.mid");
            FileInputStream fis = getFileInputStream();
            if (fis == null) {
                return false;
            }

            Log.v(TAG, "Opening file: "
                    + Uri.fromFile(getTempFile()).toString());
            // AssetFileDescriptor afd = App.getContext().getResources()
            // .openRawResourceFd(0);
            try {
                mp.setDataSource(fis.getFD()); // Uri.fromFile(tempFile).toString());
            } catch (IllegalArgumentException e) {
                e.printStackTrace();
                release();
                return false;
            } catch (IllegalStateException e) {
                e.printStackTrace();
                release();
                return false;
            } catch (IOException e) {
                e.printStackTrace();
                release();
                return false;
            }
            // mp.setOnBufferingUpdateListener(this);
            // mp.setOnCompletionListener(this);
            // mp.setOnErrorListener(this);
            // mp.setOnPreparedListener(this);
            try {
                mp.prepare();
                // mp.setLooping(true);
                mediaPrepared = true;
            } catch (IllegalStateException e) {
                e.printStackTrace();
                release();
                return false;
            } catch (IOException e) {
                e.printStackTrace();
                release();
                return false;
            }
            // Track update
            mp.setOnCompletionListener(this);
        }
        return true;
    }

    public synchronized void pause() {
        if (mediaStarted) {
            mediaPaused = true;
        }
        if (mp != null) {
            mp.pause();
        }
    }

    public synchronized void resume() {
        if (!mediaStarted || mediaPaused) {
            start();
        }

    }

    synchronized boolean start() {
        if (!prepare()) {
            return false;
        }
        try {
            mp.start();
            Log.v(TAG, String.format("Started %s", mp.toString()));
        } catch (IllegalStateException e) {
            e.printStackTrace();
            release();
            return false;
        }
        mediaStarted = true;
        mediaPaused = false;
        return true;

    }
    /*

    void setData(PositionMeta position) {

        File file = new File();
        // file.fileFormat = File.FORMAT_MULTI_TRACK;
        // file.deltaTickPerQuarterNote = 1000;
        int tempo = 120;

        Track track = new Track();
        track.add(new Event.TimeSig(0, 4, 4));
        track.add(new Event.Tempo(0, tempo));
        track.add(new Event.EndOfTrack(0));
        file.add(track);

        track = new Track();
        track.add(new Event.ProgramChange(0, 1, 25));
        for (int i = 0; i < position.getStringCount(); i++) {
            Note note = position.getNote(i);
            if (note != null) {
                // +12 for Android !
                // NOT anymore note += 12;
                track.add(new Event.NoteOn(0, 1, note.get(), 127));
                if (delay != DELAY_STRUM) {
                    track.add(new Event.NoteOff(delay, 1, note.get(), 127));
                }
            }
        }
        // track.add(new Event.NoteOn(0, 1, 42, 127));
        // track.add(new Event.NoteOn(120, 1, 44, 127));
        // track.add(new Event.NoteOn(240, 1, 46, 127));
        // track.add(new Event.NoteOff(240, 1, 46, 127));
        // track.add(new Event.NoteOff(0, 1, 42, 127));
        // track.add(new Event.NoteOff(0, 1, 44, 127));
        // track.add(new Event.NoteOn(0, 1, 42, 127));
        // track.add(new Event.NoteOff(480, 1, 42, 127));
        // // track.add(new Event.NoteOn(0, 1, 42, 127));
        // track.add(new Event.NoteOff(120, 1, 42, 127));
        // Add 5 seconds for allowing changing the volume
        if (delay == DELAY_STRUM) {
            boolean firstNote = true;
            for (int i = 0; i < position.getStringCount(); i++) {
                Note note = position.getNote(i);
                if (note != null) {
                    // +12 for Android !
                    // note += 12;
                    track.add(new Event.NoteOff(
                            firstNote ? 5 * file.deltaTickPerQuarterNote
                                    * tempo / 60 : delay, 1, note.get(), 127));
                    firstNote = false;

                }
            }
        }
        track.add(new Event.EndOfTrack(5 * file.deltaTickPerQuarterNote * tempo
                / 60));

        file.add(track);

        writeTempFile(file);
    }
*/
    /*
    PositionMeta lastPosition;

    synchronized void play(PositionMeta position) {
        if (position == null) {
            Log.v(TAG, "position null, cannot play");
            return;
        }
        release();
        if (position.equals(lastPosition)) {
            switch (delay) {
                case DELAY_FAST:
                    delay = DELAY_STRUM;
                    break;
                case DELAY_STRUM:
                    delay = DELAY_SLOW;
                    break;
                case DELAY_SLOW:
                default:
                    delay = DELAY_FAST;
                    break;
            }
        } else {
            lastPosition = position;
            delay = DELAY_FAST;
        }

        setData(position);
        start();
    }
    */

    public synchronized void release() {

        if (mp != null) {
            Log.v(TAG, String.format("Releasing... %s", mp.toString()));
            mediaPrepared = false;
            if (mediaStarted) {
                mediaStarted = false;
                mp.stop();
            }
            mp.release();
            Log.v(TAG, String.format("Released %s", mp.toString()));
            mp = null;
        }
    }

    private synchronized void release(MediaPlayer mediaPlayer) {
        if (mp == mediaPlayer) {
            release();
        }
    }

    @Override
    public void onCompletion(MediaPlayer mediaPlayer) {
        Log.v(TAG, "onCompleted " + this);
        if (mp != null) {
            Log.v(TAG,
                    String.format("Song finished %s %s", mediaPlayer.toString(),
                            mp.toString()));
            mediaCompleted = true;
            mediaPaused = true;
        }
        // release(mediaPlayer);

    }

    public void seekTo(int position) {
        if (mp != null) {
            mp.seekTo(position);
        }
    }

    Set<MediaPlayer.OnSeekCompleteListener> onSeekCompleteListeners = new HashSet<>();

    public Long getId() {
        return id;
    }

    static class SeekData {

        MediaPlayer.OnSeekCompleteListener tmpListener;
    }
    public void seekTo(int position, final MediaPlayer.OnSeekCompleteListener listener) {
        final SeekData seekData = new SeekData();
        seekData.tmpListener = new MediaPlayer.OnSeekCompleteListener() {
            @Override
            public void onSeekComplete(MediaPlayer mp) {
                onSeekCompleteListeners.remove(seekData.tmpListener);
                listener.onSeekComplete(mp);
            }
        };
        onSeekCompleteListeners.add(seekData.tmpListener);
        mp.seekTo(position);
    }

    public boolean isReady() {
        return mp != null && mediaPrepared;
    }

    public boolean isPlaying() {
        return mp != null && mediaStarted && !mediaPaused;
    }

    public boolean isCompleted() {
        return mp != null && mediaStarted && mediaCompleted;
    }

    public int getCurrentPosition() {
        return isReady() ? mp.getCurrentPosition() : 0;
    }

    public int getDuration() {
        return isReady() ? mp.getDuration() : 100;
    }

    @Override
    public void onPrepared(MediaPlayer mp) {
        Log.v(TAG, "onPrepared " + this);
        mediaPrepared = true;
    }

    @Override
    public void onSeekComplete(MediaPlayer mp) {
        Log.v(TAG, "onSeekComplete " + this);
        mediaCompleted = false;
        for (MediaPlayer.OnSeekCompleteListener listener : onSeekCompleteListeners) {
            listener.onSeekComplete(mp);
        }
    }

    @Override
    public String toString() {
        StringBuilder sb = new StringBuilder();
        sb.append(mPlayerName);
        sb.append(" ");
        if (isReady()) {
            if (isPlaying()) {
                sb.append("playing");
            } else if (mediaCompleted) {
                sb.append("completed");
            } else {
                sb.append("paused");
            }
            sb.append(" ");
            sb.append(mp.getCurrentPosition());
        } else {
            sb.append("not ready");
        }

        return sb.toString();
    }

    public void stop() {
        if (mp != null && mediaStarted) {
            mp.stop();
            mediaStarted = false;

        }
    }
}
