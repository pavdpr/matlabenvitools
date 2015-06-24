function hdr = makeBasicEnviHeader( A )
% makeBasicEnviHeader makes a basic ENVI header structure
%   
% DESCRIPTION:
%   Creates a basic ENVI header structure for use with writeenvi
%
% SYNTAX:
%   hdr = makeBasicEnviHeader( A )
%
% INPUTS:
%   A: The image ( col x line x band ) Matlab array
%
% OUTPUTS:
%   hdr: A structure containing the basic header information. 
%   hdr.bands: the number of bands
%   hdr.byteOrder: 'ieee-be' or 'ieee-le'
%   hdr.dataType: the data type (numeric)
%   hdr.fileType: the type of file (ENVI Standard)
%   hdr.interleave: the interleave (bsq)
%   hdr.lines: the number of lines
%   hdr.headerOffset: the header offset in bytes 
%   hdr.samples: the number of samples
%
% LICENSE:
%   The MIT License (MIT)
%
%   Copyright (c) 2013-2015 Rochester Institute of Technology
%
%   Permission is hereby granted, free of charge, to any person obtaining a
%   copy of this software and associated documentation files (the 
%   "Software"), to deal in the Software without restriction, including 
%   without limitation the rights to use, copy, modify, merge, publish, 
%   distribute, sublicense, and/or sell copies of the Software, and to 
%   permit persons to whom the Software is furnished to do so, subject to
%   the following conditions:
%
%   The above copyright notice and this permission notice shall be included
%   in all copies or substantial portions of the Software.
%
%   THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS
%   OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF 
%   MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. 
%   IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY 
%   CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, 
%   TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE 
%   SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
%
% AUTHOR(S):
%   Paul Romanczyk (par4249 at rit dot edu)
%
% PUBLIC REPOSITORY:
%   http://github.com/pavdpr/matlabenvitools
%
% REFERENCES:
%   http://www.exelisvis.com/docs/ENVIHeaderFiles.html
%

s = size( A );
hdr.lines = s( 1 );
hdr.samples = s( 2 );
switch numel( s )
    case 3
        hdr.bands = s( 3 );
    case 2
        hdr.bands = 1;
    otherwise
        % should have error
end
hdr.headerOffset = 0;
hdr.fileType = 'ENVI Standard';
hdr.dataType = enviGetDataType( A );
hdr.interleave = 'bsq';
hdr.byteOrder = 'ieee-le';

end

function dataType = enviGetDataType( A )
    switch class( A )
        case 'uint8'
            dataType = 1;
        case 'int16'
            dataType = 2;
        case 'int32'
            dataType = 3;
        case 'single'
            if isreal( A )
                dataType = 4;
            else
                dataType = 6;
            end
        case 'double'
            if isreal( A )
                dataType = 5;
            else
                dataType = 9;
            end
        case 'uint16'
            dataType = 12;
        case 'uint32'
            dataType = 13;
        case 'int64'
            dataType = 14;
        case 'uint64'
            dataType = 15;
        case 'float32' % same as single
            if isreal( A )
                dataType = 4;
            else
                dataType = 6;
            end
        case 'float64' % same as double
            if isreal( A )
                dataType = 5;
            else
                dataType = 9;
            end
        otherwise
            error( 'makeBasicEnviHeader:enviGetDataType:invalidDataType', ...
                [ class( A ) ' is not a valid envi data type' ] );
    end
end
