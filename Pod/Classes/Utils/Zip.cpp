//
//  Zip.cpp
//
//  Copyright 2015 mParticle, Inc.
//
//  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      http://www.apache.org/licenses/LICENSE-2.0
//
//  Unless required by applicable law or agreed to in writing, software
//  distributed under the License is distributed on an "AS IS" BASIS,
//  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//  See the License for the specific language governing permissions and
//  limitations under the License.
//

#include "Zip.h"
#include <string.h>
#include "zlib.h"

namespace mParticle {

#define ZIP_PAGE_SIZE 16384
    
    tuple<unsigned char *, unsigned int> Zip::compress(const unsigned char *data, unsigned int length) {
        tuple<unsigned char *, unsigned int> compressedData = {nullptr, 0};

        if (length == 0) {
            return {nullptr, 0};
        }
        
        z_stream strm;
        strm.zalloc = Z_NULL;
        strm.zfree = Z_NULL;
        strm.opaque = Z_NULL;
        strm.total_out = 0;
        strm.next_in = (Bytef *)data;
        strm.avail_in = length;
        
        // Compresssion Levels:
        //  Z_NO_COMPRESSION
        //  Z_BEST_SPEED
        //  Z_BEST_COMPRESSION
        //  Z_DEFAULT_COMPRESSION
        
        if (deflateInit2(&strm, Z_DEFAULT_COMPRESSION, Z_DEFLATED, (15+16), 8, Z_DEFAULT_STRATEGY) != Z_OK) {
            return {nullptr, 0};
        }
        
        unsigned int numberOfMemBlocks = 1;
        unsigned int bufferSize = numberOfMemBlocks * ZIP_PAGE_SIZE;
        get<0>(compressedData) = new unsigned char[bufferSize];
        
        do {
            if (strm.total_out >= bufferSize) {
                unsigned int previousBufferSize = bufferSize;
                unsigned char *previousData = new unsigned char[previousBufferSize];
                memmove(previousData, get<0>(compressedData), previousBufferSize);
                delete [] get<0>(compressedData);
                
                ++numberOfMemBlocks;
                bufferSize = numberOfMemBlocks * ZIP_PAGE_SIZE;
                get<0>(compressedData) = new unsigned char[bufferSize];
                memmove(get<0>(compressedData), previousData, previousBufferSize);
                delete [] previousData;
            }
            
            strm.next_out = get<0>(compressedData) + strm.total_out;
            strm.avail_out = (uInt)(bufferSize - strm.total_out);
            
            deflate(&strm, Z_FINISH);
        } while (strm.avail_out == 0);
        
        deflateEnd(&strm);
        
        get<1>(compressedData) = (unsigned int)strm.total_out;
        
        return compressedData;
    }
    
    tuple<unsigned char *, unsigned int> Zip::expand(const unsigned char *data, unsigned int length) {
        tuple<unsigned char *, unsigned int> expandedData = {nullptr, 0};

        if (length == 0) {
            return {nullptr, 0};
        }
        
        z_stream strm;
        strm.next_in = (Bytef *)data;
        strm.avail_in = length;
        strm.total_out = 0;
        strm.zalloc = Z_NULL;
        strm.zfree = Z_NULL;
        
        if (inflateInit2(&strm, (15+32)) != Z_OK) {
            return {nullptr, 0};
        }
        
        unsigned long full_length = length;
        unsigned long half_length = length / 2;
        unsigned long bufferSize = full_length + half_length;
        get<0>(expandedData) = new unsigned char[bufferSize];

        bool done = false;
        while (!done) {
            // Make sure we have enough room and reset the lengths.
            if (strm.total_out >= bufferSize) {
                unsigned long previousBufferSize = bufferSize;
                unsigned char *previousData = new unsigned char[previousBufferSize];
                memmove(previousData, get<0>(expandedData), previousBufferSize);
                delete [] get<0>(expandedData);
                
                bufferSize += half_length;
                get<0>(expandedData) = new unsigned char[bufferSize];
                memmove(get<0>(expandedData), previousData, previousBufferSize);
                delete [] previousData;
            }
            
            strm.next_out = get<0>(expandedData) + strm.total_out;
            strm.avail_out = (uInt)(bufferSize - strm.total_out);
            
            // Inflate another chunk.
            int status = inflate(&strm, Z_SYNC_FLUSH);
            
            if (status == Z_STREAM_END) {
                done = true;
            } else if (status != Z_OK) {
                break;
            }
        }
        
        if (inflateEnd(&strm) != Z_OK) {
            return {nullptr, 0};
        }
        
        if (done) {
            get<1>(expandedData) = (unsigned int)strm.total_out;
            return expandedData;
        } else {
            return {nullptr, 0};
        }
    }
}