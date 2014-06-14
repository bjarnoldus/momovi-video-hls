//-------------------------------------------------------------------------------
// Copyright (c) 2014-2013 NoZAP B.V.
// Copyright (c) 2013 Guillaume du Pontavice (https://github.com/mangui/HLSprovider)
//
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/. */
// 
// Authors:
//     Jeroen Arnoldus
//     Guillaume du Pontavice
//-------------------------------------------------------------------------------

package org.mangui.HLS.parsing {


    import org.mangui.HLS.parsing.Fragment;
    import flash.utils.ByteArray;
    import org.mangui.HLS.utils.*;

    /** HLS streaming quality level. **/
    public class Level {


        /** Audio configuration packet (ADIF). **/
        public var adif:ByteArray;
        /** Whether this is audio only. **/
        public var audio:Boolean;
        /** Video configuration packet (AVCC). **/
        public var avcc:ByteArray;
        /** Bitrate of the video in this level. **/
        public var bitrate:Number;
        /** Array with fragments for this level. **/
        public var fragments:Array;
        /** Height of the video in this level. **/
        public var height:Number;
        /** URL of this bitrate level (for M3U8). **/
        public var url:String;
        /** Width of the video in this level. **/
        public var width:Number;
        /** min sequence number from M3U8. **/
        public var start_seqnum:Number;
        /** max sequence number from M3U8. **/
        public var end_seqnum:Number;
        /** target fragment duration from M3U8 **/
        public var targetduration:Number;
        /** average fragment duration **/
        public var averageduration:Number;
        /** Total duration **/
        public var duration:Number;

        /** Create the quality level. **/
        public function Level(bitrate:Number=150000, height:Number=90, width:Number=160):void {
            this.bitrate = bitrate;
            this.height = height;
            this.width = width;
            this.fragments = new Array();
        };

        /** Return the sequence number before a given time position. **/
        public function getSeqNumBeforePosition(position:Number):Number {
          
          if(position < fragments[0].start_time)
            return start_seqnum;
         
            for(var i:Number = 0; i < fragments.length; i++) {
                  /* check whether fragment contains current position */
                if(fragments[i].start_time<=position && fragments[i].start_time+fragments[i].duration>position) {
                  return (start_seqnum+i);
                }
            }
            return end_seqnum;
        };

        /** Return the sequence number nearest a PTS **/
        public function getSeqNumNearestPTS(pts:Number,continuity:Number):Number {         
          if(fragments.length == 0) 
            return -1;
          var firstIndex:Number = getFirstIndexfromContinuity(continuity);
          if (firstIndex == -1 || fragments[firstIndex].start_pts_computed == Number.NEGATIVE_INFINITY)
            return -1;
          var lastIndex:Number = getLastIndexfromContinuity(continuity);
        
          for(var i:Number= firstIndex; i<= lastIndex; i++) {
                /* check nearest fragment */
              if( Math.abs(fragments[i].start_pts_computed-pts) < Math.abs(fragments[i].start_pts_computed+1000*fragments[i].duration-pts)) {
                return fragments[i].seqnum;
              }
          }
          // requested PTS above max PTS of this level
          return Number.POSITIVE_INFINITY;
        };
       
        public function getLevelstartPTS():Number {
          if (fragments.length)
            return fragments[0].start_pts_computed;
          else
            return Number.NEGATIVE_INFINITY;
        }

        /** Return the fragment index from fragment sequence number **/
        public function getFragmentfromSeqNum(seqnum:Number):Fragment {
            var index:Number = getIndexfromSeqNum(seqnum);
            if(index != -1) {
               return fragments[index];
            } else {
               return null;
            }
        }

        /** Return the fragment index from fragment sequence number **/
        private function getIndexfromSeqNum(seqnum:Number):Number {
            if(seqnum >= start_seqnum && seqnum <= end_seqnum) {
               return (fragments.length-1 - (end_seqnum - seqnum));
            } else {
               return -1;
            }
        }

        /** Return the first index matching with given continuity counter **/
        private function getFirstIndexfromContinuity(continuity:Number):Number {
          // look for first fragment matching with given continuity index
          for(var i:Number= 0; i< fragments.length; i++) {
            if(fragments[i].continuity == continuity)
              return i;
          }
          return -1;
        }
        
        /** Return the first seqnum matching with given continuity counter **/
        public function getFirstSeqNumfromContinuity(continuity:Number):Number {
          var index:Number = getFirstIndexfromContinuity(continuity);
          if (index == -1) {
            return Number.NEGATIVE_INFINITY;
          }
          return fragments[index].seqnum;
        }

        /** Return the last seqnum matching with given continuity counter **/
        public function getLastSeqNumfromContinuity(continuity:Number):Number {
          var index:Number = getLastIndexfromContinuity(continuity);
          if (index == -1) {
            return Number.NEGATIVE_INFINITY;
          }
          return fragments[index].seqnum;
        }


        /** Return the last index matching with given continuity counter **/
        private function getLastIndexfromContinuity(continuity:Number):Number {
          var firstIndex:Number = getFirstIndexfromContinuity(continuity);
          if (firstIndex == -1)
            return -1;
          
          var lastIndex:Number = firstIndex;
          // look for first fragment matching with given continuity index
          for(var i:Number= firstIndex; i< fragments.length; i++) {
            if(fragments[i].continuity == continuity)
              lastIndex = i;
            else
              break;
          }
          return lastIndex;
        }

        /** get current continuity index **/
        public function getContinuityIndex():Number {
            var len:Number = fragments.length;
            var frag:Fragment;
            var highestContinuity:Number = 0;
            Log.txt("BJA getContinuityIndex");

            for(var i:Number = 0; i < len; i++){
            	frag = fragments[i];
            	if(frag.continuity > highestContinuity){
            		highestContinuity = frag.continuity;
            	}
            }
            return highestContinuity;
        }
        
        /** set Discontinuity detectect in Live stream, need to update continuity index **/
        public function updateContinuityFragmentsFromSeqNum(seqnum:Number,continuity:Number):void {
            var len:Number = fragments.length;
            var frag:Fragment;
            Log.txt("BJA updateContinuityFragmentsFromSeqNum to continuity index: " + continuity + " len:" + len + " seqnum:" + seqnum);
            for(var i:Number = 0; i < len; i++) {
              frag = fragments[i];
              if(frag.seqnum >= seqnum ){
	              Log.txt("BJA Found fragment to update: " + frag.url + " continuity:" + frag.continuity);
    	          frag.continuity = continuity;
        	      Log.txt("BJA Result of update: " + frag.url + " continuity:" + frag.continuity);
			   }
            }
    	}
    	
        /** set Fragments **/
        public function updateFragments(_fragments:Array):void {
            var idx_with_pts:Number = -1;
            var len:Number = _fragments.length;
            var frag:Fragment;
            // update PTS from previous fragments
            for(var i:Number = 0; i < len; i++) {
              frag = getFragmentfromSeqNum(_fragments[i].seqnum);
              if(frag != null && frag.start_pts != Number.NEGATIVE_INFINITY) {
                _fragments[i].start_pts = frag.start_pts;
                _fragments[i].duration = frag.duration;
                _fragments[i].continuity = frag.continuity; //BJA KEEP CONTINUITY OF OLD FRAGMENT
                idx_with_pts = i;
              }
            }
            fragments = _fragments;
            start_seqnum = _fragments[0].seqnum;
            end_seqnum = _fragments[len-1].seqnum;
            
            if(idx_with_pts !=-1) {
              // if at least one fragment contains PTS info, recompute PTS information for all fragments
              updatePTS(fragments[idx_with_pts].seqnum, fragments[idx_with_pts].start_pts,fragments[idx_with_pts].start_pts+1000*fragments[idx_with_pts].duration);
            } else {
              duration = _fragments[len-1].start_time + _fragments[len-1].duration;
            }
            averageduration = duration/len;
        }
      
      private function updateFragmentPTS(from_index:Number, to_index:Number):void {
        //Log.txt("updateFragmentPTS from/to:" + from_index + "/" + to_index);
        var frag_from:Fragment = fragments[from_index];
        var frag_to:Fragment = fragments[to_index];
        
        if (frag_to.start_pts != Number.NEGATIVE_INFINITY) {
          // we know PTS[to_index]
          frag_to.start_pts_computed = frag_to.start_pts;
        // update duration to fix drifts between playlist and fragment
              if(to_index > from_index)
                frag_from.duration = (frag_to.start_pts -frag_from.start_pts_computed)/1000;
              else
                frag_to.duration = (frag_from.start_pts_computed -frag_to.start_pts)/1000;
        } else {
          // we dont know PTS[to_index]
          if(to_index > from_index)
            frag_to.start_pts_computed = frag_from.start_pts_computed + 1000*frag_from.duration;
          else
            frag_to.start_pts_computed = frag_from.start_pts_computed - 1000*frag_to.duration;
          }
      }
      
      public function updatePTS(seqnum:Number, min_pts:Number,max_pts:Number) : Number {
        //Log.txt("updatePTS : seqnum/min/max:" + seqnum + '/' + min_pts + '/' + max_pts);
        // get fragment from seqnum
        var fragIdx:Number = getIndexfromSeqNum(seqnum);
        if (fragIdx!=-1) {
          var frag:Fragment = fragments[fragIdx];
          // update fragment start PTS + duration
          frag.start_pts = min_pts;
          frag.start_pts_computed = min_pts;
          frag.duration = (max_pts-min_pts)/1000;
          //Log.txt("SN["+fragments[fragIdx].seqnum+"]:pts/duration:" + fragments[fragIdx].start_pts_computed + "/" + fragments[fragIdx].duration);

          // adjust fragment PTS/duration from seqnum-1 to frag 0
          for(var i:Number = fragIdx ; i > 0 && fragments[i-1].continuity == frag.continuity; i--) {
            updateFragmentPTS(i,i-1);
            //Log.txt("SN["+fragments[i-1].seqnum+"]:pts/duration:" + fragments[i-1].start_pts_computed + "/" + fragments[i-1].duration);
          }
         
         // adjust fragment PTS/duration from seqnum to last frag
          for(i = fragIdx ; i < fragments.length-1 && fragments[i+1].continuity == frag.continuity; i++) {
            updateFragmentPTS(i,i+1);
            //Log.txt("SN["+fragments[i+1].seqnum+"]:pts/duration:" + fragments[i+1].start_pts_computed + "/" + fragments[i+1].duration);
          }

          // second, adjust fragment offset
           var start_time_offset:Number = fragments[0].start_time;
           for(i= 0; i < fragments.length; i++) {
              fragments[i].start_time = start_time_offset;
              start_time_offset+=fragments[i].duration;
              //Log.txt("SN["+fragments[i].seqnum+"]:start_time/continuity/pts/duration:" + fragments[i].start_time + "/" + fragments[i].continuity + "/"+ fragments[i].start_pts_computed + "/" + fragments[i].duration);
           }
           duration = start_time_offset;
           return frag.start_time;
        } else {
          return 0;
        }
      }
    }
}