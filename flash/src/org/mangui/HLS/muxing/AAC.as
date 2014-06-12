package org.mangui.HLS.muxing {


    import org.mangui.HLS.utils.*;
    import flash.utils.ByteArray;


    /** Constants and utilities for the AAC audio format. **/
    public class AAC {


        /** ADTS Syncword (111111111111), ID (MPEG4), layer (00) and protection_absent (1).**/
        public static const SYNCWORD:uint =  0xFFF1;
        /** ADTS Syncword with MPEG2 stream ID (used by e.g. Squeeze 7). **/
        public static const SYNCWORD_2:uint =  0xFFF9;
        /** ADTS Syncword with MPEG2 stream ID (used by e.g. Envivio 4Caster). **/
        public static const SYNCWORD_3:uint =  0xFFF8;
        /** ADTS/ADIF sample rates index. **/
        public static const RATES:Array = 
            [96000,88200,64000,48000,44100,32000,24000,22050,16000,12000,11025,8000,7350];
        /** ADIF profile index (ADTS doesn't have Null). **/
        public static const PROFILES:Array = ['Null','Main','LC','SSR','LTP','SBR'];


        /** Get ADIF header from ADTS stream. **/
        public static function getADIF(adts:ByteArray,position:Number=0):ByteArray {
            adts.position = position;
            var short:uint = adts.readUnsignedShort();
            if(short == SYNCWORD || short == SYNCWORD_2 || short == SYNCWORD_3) {
                var profile:uint = (adts.readByte() & 0xF0) >> 6;
                // Correcting zero-index of ADIF and Flash playing only LC/HE.
                if (profile > 3) { profile = 5; } else { profile = 2; }
                adts.position--;
                var srate:uint = (adts.readByte() & 0x3C) >> 2;
                adts.position--;
                var channels:uint = (adts.readShort() & 0x01C0) >> 6;
            } else {
                throw new Error("Stream did not start with ADTS header.");
                return;
            }
            // 5 bits profile + 4 bits samplerate + 4 bits channels.
            var adif:ByteArray = new ByteArray();
            adif.writeByte((profile << 3) + (srate >> 1));
            adif.writeByte((srate << 7) + (channels << 3));
            // Log.txt('AAC: '+PROFILES[profile] + ', '+RATES[srate]+' Hz '+ channels +' channel(s)');
            // Reset position and return adif.
            adts.position -= 4;
            adif.position = 0;
            return adif;
        };


        /** Get a list with AAC frames from ADTS stream. **/
        public static function getFrames(adts:ByteArray,position:Number=0):Array {
            var frames:Array = [];
            var frame_start:uint;
            var frame_length:uint;
            // Get raw AAC frames from audio stream.
            adts.position = position;
            var samplerate:uint;
            // we need at least 6 bytes, 2 for sync word, 4 for frame length
            while(adts.bytesAvailable > 5) {
                // Check for ADTS header
                var short:uint = adts.readUnsignedShort();
                if(short == SYNCWORD || short == SYNCWORD_2 || short == SYNCWORD_3) {
                    // Store samplerate for ofsetting timestamps.
                    if(!samplerate) {
                        samplerate = RATES[(adts.readByte() & 0x3C) >> 2];
                        adts.position--;
                    }
                    // Store raw AAC preceding this header.
                    if(frame_start) {
                        frames.push({
                            start: frame_start,
                            length: frame_length,
                            rate: samplerate
                        });
                    }
                    if(short == SYNCWORD_3) {
                       // ADTS header is 9 bytes.
                       frame_length = ((adts.readUnsignedInt() & 0x0003FFE0) >> 5) - 9;
                       frame_start = adts.position + 3;
                       adts.position += frame_length + 3;
                  } else {
                       // ADTS header is 7 bytes.
                       frame_length = ((adts.readUnsignedInt() & 0x0003FFE0) >> 5) - 7;
                       frame_start = adts.position + 1;
                       adts.position += frame_length + 1;
                  }
                } else {
                    throw new Error("ADTS frame length incorrect.");
                }
            }
            // Write raw AAC after last header.
            if(frame_start) {
                frames.push({
                    start:frame_start,
                    length:frame_length,
                    rate:samplerate
                });
                // Log.txt("AAC: "+frames.length+" ADTS frames");
            } else {
                throw new Error("No ADTS headers found in this stream.");
            }
            adts.position = position;
            return frames;
        };


    }


}