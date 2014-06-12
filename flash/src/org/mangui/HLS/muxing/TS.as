package org.mangui.HLS.muxing {
	
	
	import org.mangui.HLS.muxing.*;
	import org.mangui.HLS.utils.Log;
	
	import flash.events.Event;
	import flash.events.EventDispatcher;
	import flash.events.TimerEvent;
	import flash.utils.ByteArray;
	import flash.utils.Timer;
	
	
	/** Representation of an MPEG transport stream. **/
	public class TS extends EventDispatcher {
		
		
		/** TS Sync byte. **/
		public static const SYNCBYTE:uint = 0x47;
		/** TS Packet size in byte. **/
		public static const PACKETSIZE:uint = 188;
		/** Identifier for read complete event **/
		public static const READCOMPLETE:String = "readComplete"
		private static const COUNT:uint = 5000;	
		
		
		/** Packet ID of the AAC audio stream. **/
		private var _aacId:Number = -1;
		/** List with audio frames. **/
		public var audioTags:Vector.<Tag> = new Vector.<Tag>();
		/** List of packetized elementary streams with AAC. **/
		private var _audioPES:Vector.<PES> = new Vector.<PES>();
		/** has PMT been parsed ? **/
		private var _pmtParsed:Boolean= false;
		/** nb of AV packets before PMT **/
		private var _AVpacketsBeforePMT:Number = 0;
		/** Packet ID of the video stream. **/
		private var _avcId:Number = -1;
		/** PES packet that contains the first keyframe. **/
		private var _firstKey:Number = -1;
		/** Packet ID of the MP3 audio stream. **/
		private var _mp3Id:Number = -1;
		/** Packet ID of the PAT (is always 0). **/
		private var _patId:Number = 0;
		/** Packet ID of the Program Map Table. **/
		private var _pmtId:Number = -1;
		/** List with video frames. **/
		/** Packet ID of the SDT (is always 17). **/
		private var _sdtId:Number = 17;
		public var videoTags:Vector.<Tag> = new Vector.<Tag>();
		/** List of packetized elementary streams with AVC. **/
		private var _videoPES:Vector.<PES> = new Vector.<PES>();
		/** Timer for reading packets **/ 
		public var _timer:Timer;
		/** Byte data to be read **/
		private var _data:ByteArray;
		/* last PES packet containing AVCC Frame (SPS/PPS) */
		private var _lastAVCCFrame:PES = null;
		
		
		/** Transmux the M2TS file into an FLV file. **/
		public function TS(data:ByteArray) {
			// Extract the elementary streams.
			_data = data;
			_timer = new Timer(0,0);
			_timer.addEventListener(TimerEvent.TIMER, _readData);
		};
		
		/** add new data into Buffer */
		public function addData(newData:ByteArray):void {
		  newData.readBytes(_data,_data.position);
		  _timer.start();
		}
		
		/** Read a small chunk of packets each time to avoid blocking **/
		private function _readData(e:Event):void {
			var i:uint = 0;
			while(_data.bytesAvailable && i < COUNT) {
				_readPacket();
				i++;
				
			}
			if (!_data.bytesAvailable) {
				_timer.stop();
				_extractFrames();
			}
		}
		
		/** start the timer in order to start reading data **/
		public function startReading():void {;
			_timer.start();
		}
		
		/** setup the video and audio tag vectors from the read data **/
		private function _extractFrames():void {
			if (_videoPES.length == 0 && _audioPES.length == 0 ) {
				throw new Error("No AAC audio and no AVC video stream found.");
			}
			// Extract the ADTS or MPEG audio frames.
			if(_aacId > 0) {
				_readADTS();
			} else {
				_readMPEG();
			}
			// Extract the NALU video frames.
			_readNALU();
			dispatchEvent(new Event(TS.READCOMPLETE));
		}
		
		/** Get audio configuration data. **/
		public function getADIF():ByteArray {
			if(_aacId > 0 && audioTags.length > 0) {
				return AAC.getADIF(_audioPES[0].data,_audioPES[0].payload);
			} else { 
				return new ByteArray();
			}
		};
		
		
		/** Get video configuration data. **/
		public function getAVCC():ByteArray {
			if(_firstKey == -1) {
				return new ByteArray();
			}
			return AVC.getAVCC(_lastAVCCFrame.data,_lastAVCCFrame.payload);
		};
		
		
		/** Read ADTS frames from audio PES streams. **/
		private function _readADTS():void {
			var frames:Array;
			var overflow:Number = 0;
			var tag:Tag;
			var stamp:Number;
			for(var i:Number=0; i<_audioPES.length; i++) {
				// Parse the PES headers.
				_audioPES[i].parse();
				// Correct for Segmenter's "optimize", which cuts frames in half.
				if(overflow > 0) {
					_audioPES[i-1].data.position = _audioPES[i-1].data.length;
					_audioPES[i-1].data.writeBytes(_audioPES[i].data,_audioPES[i].payload,overflow);
					_audioPES[i].payload += overflow;
				}
				// Store ADTS frames in array.
				frames = AAC.getFrames(_audioPES[i].data,_audioPES[i].payload);
				for(var j:Number=0; j< frames.length; j++) {
					// Increment the timestamp of subsequent frames.
					stamp = Math.round(_audioPES[i].pts + j * 1024 * 1000 / frames[j].rate);
					tag = new Tag(Tag.AAC_RAW, stamp, stamp, false);
					if(i == _audioPES.length-1 && j == frames.length - 1) {
					  if((_audioPES[i].data.length - frames[j].start)>0) {
						  tag.push(_audioPES[i].data, frames[j].start, _audioPES[i].data.length - frames[j].start);
					  }
					} else { 
						tag.push(_audioPES[i].data, frames[j].start, frames[j].length);
					}
					audioTags.push(tag);
				}
				// Correct for Segmenter's "optimize", which cuts frames in half.
				overflow = frames[frames.length-1].start +
					frames[frames.length-1].length - _audioPES[i].data.length;
			}
		};
		
		
		/** Read MPEG data from audio PES streams. **/
		private function _readMPEG():void {
			var tag:Tag;
			for(var i:Number=0; i<_audioPES.length; i++) {
				_audioPES[i].parse();
				tag = new Tag(Tag.MP3_RAW, _audioPES[i].pts,_audioPES[i].dts, false);
				tag.push(_audioPES[i].data, _audioPES[i].payload, _audioPES[i].data.length-_audioPES[i].payload);
				audioTags.push(tag);
			}
		};
		
		
		/** Read NALU frames from video PES streams. **/
		private function _readNALU():void {
			var overflow:Number;
			var units:Array;
			var last:Number;
			for(var i:Number=0; i<_videoPES.length; i++) {
				// Parse the PES headers and NAL units.
				try { 
					_videoPES[i].parse();
				} catch (error:Error) {
					Log.txt(error.message);
					continue;
				}
				units = AVC.getNALU(_videoPES[i].data,_videoPES[i].payload);
				// If there's no NAL unit, push all data in the previous tag.
				if(!units.length) {
					videoTags[videoTags.length-1].push(_videoPES[i].data, _videoPES[i].payload,
						_videoPES[i].data.length - _videoPES[i].payload);
					continue;
				}
				// If NAL units are offset, push preceding data into the previous tag.
				overflow = units[0].start - units[0].header - _videoPES[i].payload;
				if(overflow) {
					videoTags[videoTags.length-1].push(_videoPES[i].data,_videoPES[i].payload,overflow);
				}
				videoTags.push(new Tag(Tag.AVC_NALU,_videoPES[i].pts,_videoPES[i].dts,false));
				// Only push NAL units 1 to 5 into tag.
				for(var j:Number = 0; j < units.length; j++) {
					if (units[j].type < 6) {
						videoTags[videoTags.length-1].push(_videoPES[i].data,units[j].start,units[j].length);
						// Unit type 5 indicates a keyframe.
						if(units[j].type == 5) {
							videoTags[videoTags.length-1].keyframe = true;
						}
					} else if (units[j].type == 7 || units[j].type == 8) {
							if(_firstKey == -1) {
								_firstKey = i;
								_lastAVCCFrame=_videoPES[i];
							}
					}
				}
			}
		};
		
		
		/** Read TS packet. **/
		private function _readPacket():void {	
			// Each packet is 188 bytes.
			var todo:uint = TS.PACKETSIZE;
			// Sync byte.
			if(_data.readByte() != TS.SYNCBYTE) {
				throw new Error("Could not parse TS file: sync byte not found.");
			}
			todo--;
			// Payload unit start indicator.
			var stt:uint = (_data.readUnsignedByte() & 64) >> 6;
			_data.position--;
			
			// Packet ID (last 13 bits of UI16).
			var pid:uint = _data.readUnsignedShort() & 8191;
			// Check for adaptation field.
			todo -=2;
			var atf:uint = (_data.readByte() & 48) >> 4;
			todo --;
			// Read adaptation field if available.
			if(atf > 1) {
				// Length of adaptation field.
				var len:uint = _data.readUnsignedByte();
				todo--;
				// Random access indicator (keyframe).
				//var rai:uint = data.readUnsignedByte() & 64;
				_data.position += len;
				todo -= len;
				// Return if there's only adaptation field.
				if(atf == 2 || len == 183) {
					_data.position += todo;
					return;
				}
			}
			
			var pes:ByteArray = new ByteArray();
			// Parse the PES, split by Packet ID.
			switch (pid) {
				case _patId:
					todo -= _readPAT();
					break;
				case _pmtId:
					todo -= _readPMT();
					break;
				case _aacId:
				case _mp3Id:
					if(stt) {
						pes.writeBytes(_data,_data.position,todo);
						_audioPES.push(new PES(pes,true));
					} else if (_audioPES.length) {
						_audioPES[_audioPES.length-1].data.writeBytes(_data,_data.position,todo);
					} else {
						Log.txt("Discarding TS audio packet with id "+pid);
					}
					break;
				case _avcId:
					if(stt) {
						pes.writeBytes(_data,_data.position,todo);
						_videoPES.push(new PES(pes,false));
					} else if (_videoPES.length) {
						_videoPES[_videoPES.length-1].data.writeBytes(_data,_data.position,todo);
					} else {
						Log.txt("Discarding TS video packet with id "+pid + " bad TS segmentation ?");
					}
					break;
				case _sdtId:
						break;
				default:
				_AVpacketsBeforePMT++;
					break;
			}
			// Jump to the next packet.
			_data.position += todo;
		};
		
		
		/** Read the Program Association Table. **/
		private function _readPAT():Number {
			// Check the section length for a single PMT.
			_data.position += 3;
			if(_data.readUnsignedByte() > 13) {
				throw new Error("Multiple PMT entries are not supported.");
			}
			// Grab the PMT ID.
			_data.position += 7;
			_pmtId = _data.readUnsignedShort() & 8191;
			return 13;
		};
		
		
		/** Read the Program Map Table. **/
		private function _readPMT():Number {
			// Check the section length for a single PMT.
			_data.position += 3;
			var len:uint = _data.readByte();
			var read:uint = 13;
			_data.position += 8;
			var pil:Number = _data.readByte();
			_data.position += pil;
			read += pil;
			// Loop through the streams in the PMT.
			while(read < len) {
				var typ:uint = _data.readByte();
				var sid:uint = _data.readUnsignedShort() & 8191;
				if(typ == 0x0F) {
					_aacId = sid;
				} else if (typ == 0x1B) {
					_avcId = sid;
				} else if (typ == 0x03 || typ == 0x04) {
					_mp3Id = sid;
				}
				//  descriptor loop length
				_data.position++;
				var sel:uint = _data.readByte() & 0x3F;
				_data.position += sel;
				read += sel + 5;
			}
			if(_pmtParsed == false) {
			  _pmtParsed = true;
			// if PMT was not parsed before, and some unknown packets have been skipped in between, rewind to beginning of the stream
			// it helps with fragment not segmented properly (in theory there should be no A/V packets before PAT/PMT)
			  if (_AVpacketsBeforePMT > 1) {
			    Log.txt("late PMT found, rewinding at beginning of TS");
			    return (-_data.position);
			  }
		  }
			return len;
		};
	}
}