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


    /** HLS streaming chunk. **/
    public class Fragment {


        /** Duration of this chunk. **/
        public var duration:Number;
        /** Start time of this chunk. **/
        public var start_time:Number;
        /** Start PTS of this chunk. **/
        public var start_pts:Number;
        /** computed Start PTS of this chunk. **/
        public var start_pts_computed:Number;
        /** sequence number of this chunk. **/
        public var seqnum:Number;
        /** URL to this chunk. **/
        public var url:String;
        /** continuity index of this chunk. **/
        public var continuity:Number;



        /** Create the fragment. **/
        public function Fragment(url:String, duration:Number, seqnum:Number,start_time:Number,continuity:Number):void {
            this.duration = duration;
            this.url = url;
            this.seqnum = seqnum;
            this.start_time = start_time;
            this.continuity = continuity;
            this.start_pts = Number.NEGATIVE_INFINITY;
            this.start_pts_computed = Number.NEGATIVE_INFINITY;
        };
    }


}