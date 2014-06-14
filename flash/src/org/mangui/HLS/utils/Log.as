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

package org.mangui.HLS.utils {


    import flash.external.ExternalInterface;


    /** Class that sends log messages to browser console. **/
    public class Log {


        public static var LOGGING:Boolean = true;


        /** Log a message to the console. **/
        public static function txt(message:*):void {
            if(LOGGING){
                if(ExternalInterface.available)
                    ExternalInterface.call('console.log',String(message));
                else trace(message);
            }
        };


    };


}