package org.mangui.HLS.muxing {


    import org.mangui.HLS.utils.*;
    import flash.utils.ByteArray;


    /** Constants and utilities for the H264 video format. **/
    public class AVC {


        /** H264 NAL unit names. **/
        public static const NAMES:Array = [
            'Unspecified',                  // 0
            'NDR',                          // 1
            'Partition A',                  // 2
            'Partition B',                  // 3
            'Partition C',                  // 4
            'IDR',                          // 5
            'SEI',                          // 6
            'SPS',                          // 7
            'PPS',                          // 8
            'AUD',                          // 9
            'End of Sequence',              // 10
            'End of Stream',                // 11
            'Filler Data'                   // 12
        ];
        /** H264 profiles. **/
        public static const PROFILES:Object = {
            '66': 'H264 Baseline',
            '77': 'H264 Main',
            '100': 'H264 High'
        };


        /** Get Avcc header from AVC stream 
        See ISO 14496-15, 5.2.4.1 for the description of AVCDecoderConfigurationRecord
        **/
        public static function getAVCC(nalu:ByteArray,position:Number=0):ByteArray {
            // Find SPS and PPS units in AVC stream.
            var units:Array = AVC.getNALU(nalu,position,false);
            var sps:Number = -1;
            var pps:Number = -1;
            for(var i:Number = 0; i< units.length; i++) {
                if(units[i].type == 7 && sps == -1) {
                    sps = i;
                } else if (units[i].type == 8 && pps == -1) {
                    pps = i;
                }
            }
            // Throw errors if units not found.
            if(sps == -1) {
                throw new Error("No SPS NAL unit found in this stream.");
            } else if (pps == -1) {
                throw new Error("No PPS NAL unit found in this stream.");
            }
            // Write startbyte
            var avcc:ByteArray = new ByteArray();
            avcc.writeByte(0x01);
            // Write profile, compatibility and level.
            avcc.writeBytes(nalu,units[sps].start+1, 3);
            // reserved (6 bits), NALU length size - 1 (2 bits)
            avcc.writeByte(0xFC | 3);
            // reserved (3 bits), num of SPS (5 bits)
            avcc.writeByte(0xE0 | 1);
            // 2 bytes for length of SPS
            avcc.writeShort(units[sps].length);
            // data of SPS
            avcc.writeBytes(nalu,units[sps].start,units[sps].length);
            // Number of PPS
            avcc.writeByte(0x01);
            // 2 bytes for length of PPS
            avcc.writeShort(units[pps].length);
            // data of PPS
            avcc.writeBytes(nalu,units[pps].start,units[pps].length);
            // Grab profile/level
            avcc.position = 1;
            var prf:Number = avcc.readByte();
            avcc.position = 3;
            var lvl:Number = avcc.readByte();
            avcc.position = 0;
            // Log.txt("AVC: "+PROFILES[prf]+' level '+lvl);
            return avcc;
        };


        /** Return an array with NAL delimiter indexes. **/
        public static function getNALU(nalu:ByteArray,position:Number=0,log:Boolean=true):Array {
            var units:Array = [];
            var unit_start:Number;
            var unit_type:Number;
            var unit_header:Number;
            // Loop through data to find NAL startcodes.
            var window:uint = 0;
            nalu.position = position;
            while(nalu.bytesAvailable > 4) {
                window = nalu.readUnsignedInt();
                // Match four-byte startcodes
                if((window & 0xFFFFFFFF) == 0x01) {
                  // push previous NAL unit if new start delimiter found, dont push unit with type = 0
                    if(unit_start && unit_type) {
                        units.push({
                            header: unit_header,
                            length: nalu.position - 4 - unit_start,
                            start: unit_start,
                            type: unit_type
                        });
                    }
                    unit_header = 4;
                    unit_start = nalu.position;
                    unit_type = nalu.readByte() & 0x1F;
                    // NDR or IDR NAL unit
                    if(unit_type == 1 || unit_type == 5) { break; }
                // Match three-byte startcodes
                } else if((window & 0xFFFFFF00) == 0x100) {
                    // push previous NAL unit if new start delimiter found, dont push unit with type = 0
                    if(unit_start && unit_type) {
                        units.push({
                            header: unit_header,
                            length: nalu.position - 4 - unit_start,
                            start: unit_start,
                            type: unit_type
                        });
                    }
                    nalu.position--;
                    unit_header = 3;
                    unit_start = nalu.position;
                    unit_type = nalu.readByte() & 0x1F;
                    // NDR or IDR NAL unit
                    if(unit_type == 1 || unit_type == 5) { break; }
                } else {
                    nalu.position -= 3;
                }
            }
            // Append the last NAL to the array.
            if(unit_start) {
                units.push({
                    header: unit_header,
                    length: nalu.length - unit_start,
                    start: unit_start,
                    type: unit_type
                });
            }
            // Reset position and return results.
            if(log) {
                if(units.length) {
                    var txt:String = "AVC: ";
                    for(var i:Number=0; i<units.length; i++) { 
                        txt += NAMES[units[i].type] + ", ";
                    }
                    // Log.txt(txt.substr(0,txt.length-2) + " slices");
                } else {
                   // Log.txt('AVC: no NALU slices found');
                }
            }
            nalu.position = position;
            return units;
        };


    }


}