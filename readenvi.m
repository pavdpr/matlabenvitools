function [ A, header ] = readenvi( fname, verbose )
% READENVI reads and envi image
%
% DESCRIPTION:
%   Reads an image of ENVI standard type  to a [col x line x band] MATLAB 
%   array
%
% SYNTAX:
%   A=readenvi(filename)
%   [A,header]=readenvi(filename)
%   ...=readenvi(fname,verbose)
%
% INPUTS:
%   fname: string giving the full pathname of the ENVI image to read.
%   verbose: (optional, default = 0) 1 to display verbose outputs, 0 to not
%       display outputs
%
% OUTPUTS:
%   A: The image ( col x line x band ) Matlab array
%   header: A structure containing the header information
%   header.bandNames:
%	header.bands: the number of bands
%   header.bbl:
%   header.byteOrder: 'ieee-be' or 'ieee-le'
%   header.coordinateSystemString a string containing the coordinate system
%       information. This is NOT parsed in any way.
%   header.dataType: the data type (numeric)
%   header.dataTypeName: the data type (string)
%   header.description: a string description
%   header.fileType: the type of file
%   header.fwhm: the full width half max
%   header.isComplex: true if complex data, false otherwise
%   header.lines: the number of lines
%   header.headerOffset: the header offset in bytes 
%   header.mapInfo: the map projection info
%     mapInfo.projectionName: the coordinate space
%     mapInfo.xReferencePixelLocation: the x reference pixel location
%     mapInfo.yReferencePixelLocation: the y reference pixel location
%     mapInfo.pixelEasting: the easting of the reference pixel
%     mapInfo.pixelNorthing: the northing of the reference pixel
%     mapInfo.xPixelSize: the x size of a pixel
%     mapInfo.yPixelSize: thy y size of a pixel
%     mapInfo.projectionZone: the zone (UTM only)
%     mapInfo.northSouth: north or south (UTM only)
%     mapInfo.datum: the reference datum
%     mapInfo.units: the units of the coordinates
%   header.samples: the number of samples
%   header.sensorType = hdr.other( idx ).value;
%   header.wavelength: the list of wavelengths
%   header.wavelengthUnits = ...
%   header.other: an array of key/value structures with the fields that are
%       not explicitly parsed by this function. Both key and value are
%       strings.
%   header.xStart - Defines the image coordinates for the upper-left pixel 
%       in the image.
%   header.yStart - Defines the image coordinates for the upper-left pixel 
%       in the image.
%
% NOTES:
%   -readenvi needs the corresponding image header file generated
%   automatically by ENVI. The ENVI header file must have the same name as 
%   the ENVI image file + the '.hdr' extension.
%   -Depending on the contents of the ENVI header file, some tags in the  
%   header structure may not be populated.
%   -Complex data will not be properly read in.
%
% TODO:
%   - Fix the reading of complex data
%   - Parse coordinate system string
%   - Switch from C++ thinking and make use of strsplit.
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


% if verbose is not set, make it false
if nargin < 2
    verbose = false;
end
if verbose
    tic
end

% Check user input
if ~ischar( fname )
    error( 'readenvi:invalidInput', 'fname should be a char string' );
end

% Open ENVI header file
if verbose
    fprintf( [ 'Looking for: "' strcat( fname, '.hdr' ) '"' ] );
end
fid = fopen( strcat( fname, '.hdr' ), 'r' );

% Check that the file is valid
if fid == -1
    if verbose
        fprintf( '....Not Found\n' );
    end
    % first try stripping the .img and replace with .hdr
    loc = strfind( fname, '.' );
    if numel( loc ) > 0
        fname_base = fname( 1:( loc( end ) - 1 ) );
    else
        fname_base = fname;
    end
    fid = fopen( strcat( fname_base, '.hdr' ), 'r' );
    if verbose
        fprintf( [ 'Looking for: "' strcat( fname_base, '.hdr' ) '"' ] );
    end
end


% check to make  sure it opened that time
if fid == -1 %true error   
    if verbose
        fprintf( '....Not Found\n' );
    end
    error( 'readenvi:noHeaderFile', ...
        [ 'Can''t find the input header file.\nImageFile: ' fname '\n' ]);
else
    if verbose
        fprintf( '....Found!\n' );
    end
end

% Read ENVI header
header = readENVIheader( fid, verbose );
fclose( fid );

if verbose
    % Open the ENVI image and store it in the 'A' MATLAB array
    fprintf( 'File: %s\n', fname );
    fprintf( [ '\tOpening file with: ' num2str( header.samples ) ' cols x ', ...
        num2str( header.lines ) ' lines x ', ...
        num2str( header.bands ) ' bands\n' ] );
    fprintf( [ '\tof type ' header.dataTypeName ' and interleave ' ...
        header.interleave '\n' ] );
    
    fprintf( '\t' );
    toc
end

% I probably should add checks to make sure the necessary parameters are
% known

% read the image!
A = multibandread( fname, ...
    [ header.lines, header.samples, header.bands ], ...
    header.dataTypeName, ...
    header.headerOffset, ...
    header.interleave, ...
    header.byteOrder );

A = makeImageRightType( A, header.dataType );

end

function hdr = readENVIheader( fid, verbose )
    % make sure 'ENVI' is the first line of the header
    line = fgetl( fid );
    if ( ( ~strcmp( line, 'ENVI' ) ) && ( verbose ) )
        warning( 'readenvi:readENVIheader:headerWarning', ...
            'This file may not be an ENVI header file' );
    end
    
    hdr.other = [];
    
    % read the header into a key/string value pairs. We will parse the
    % strings into numerical values later!
    while ~feof( fid )
        [ key, value ] = readENVIheaderLine( fid );
        tmp.key = key;
        tmp.value = value;
        hdr.other = [ hdr.other tmp ];
    end
    % parse the header into useful parts
    idx = 1;
    while idx <= numel( hdr.other )
        switch hdr.other( idx ).key
            % defined keys are listed in alphabetical order
            case 'band names'
                hdr.bandNames = ...
                    parseCommaSeparatedValues( hdr.other( idx ).value );
                hdr.other = removeFromOther( hdr.other, idx );
            case 'bands'
                hdr.bands = str2double( hdr.other( idx ).value );
                hdr.other = removeFromOther( hdr.other, idx );
            case 'bbl'
                hdr.bbl = ...
                    parseCommaSeparatedDouble( hdr.other( idx ).value );
                hdr.other = removeFromOther( hdr.other, idx );
            case 'byte order'
                if ( str2double( hdr.other( idx ).value ) == 1 )
                    hdr.byteOrder = 'ieee-be';
                else
                    hdr.byteOrder = 'ieee-le';
                end
                hdr.other = removeFromOther( hdr.other, idx );
            case 'coordinate system string'
                hdr.coordinateSystemString = hdr.other( idx ).value;
                hdr.other = removeFromOther( hdr.other, idx );
            case 'data type'
                hdr.dataType = str2double( hdr.other( idx ).value );
                hdr.other = removeFromOther( hdr.other, idx );                
                [ hdr.dataTypeName, hdr.isComplex ] = ...
                    convertDataType( hdr.dataType );
            case 'dem band'
                hdr.demBand = str2double( hdr.other( idx ).value );
                hdr.other = removeFromOther( hdr.other, idx );
            case 'dem file'
                hdr.demFile = hdr.other( idx ).value;
                hdr.other = removeFromOther( hdr.other, idx );
            case 'description'
                hdr.description = hdr.other( idx ).value;
                hdr.other = removeFromOther( hdr.other, idx );
            case 'file type'
                hdr.fileType = hdr.other( idx ).value;
                hdr.other = removeFromOther( hdr.other, idx );
            case 'fwhm'
                hdr.fwhm = ...
                    parseCommaSeparatedDouble( hdr.other( idx ).value );
                hdr.other = removeFromOther( hdr.other, idx );
            case 'geo points'
                hdr.geoPoints = ...
                    parseCommaSeparatedDouble( hdr.other( idx ).value );
                hdr.other = removeFromOther( hdr.other, idx );
            case 'header offset' 
                hdr.headerOffset = str2double( hdr.other( idx ).value );
                hdr.other = removeFromOther( hdr.other, idx );
            case 'interleave'  
                hdr.interleave = hdr.other( idx ).value;
                hdr.other = removeFromOther( hdr.other, idx );
            case 'lines'     
                hdr.lines = str2double( hdr.other( idx ).value );
                hdr.other = removeFromOther( hdr.other, idx );
            case 'map info'
                tmp = parseCommaSeparatedValues( hdr.other( idx ).value );
                hdr.other = removeFromOther( hdr.other, idx );
                info.projectionName = tmp{ 1 };
                info.xReferencePixelLocation = str2double( tmp{ 2 } );
                info.yReferencePixelLocation = str2double( tmp{ 3 } );
                info.pixelEasting = str2double( tmp{ 4 } );
                info.pixelNorthing = str2double( tmp{ 5 } );
                info.xPixelSize = str2double( tmp{ 6 } );
                info.yPixelSize = str2double( tmp{ 7 } );
                if strcmpi( info.projectionName, 'UTM' )
                    info.projectionZone = str2double( tmp{ 8 } );
                    info.northSouth = tmp{ 9 };
                    info.datum = tmp{ 10 };
                    info.units = tmp{ 11 };
                elseif strcmpi( info.projectionName, 'By WKT String' )
                    % nothing to do
                else
                    info.datum = tmp{ 8 };
                    info.units = tmp{ 9 };
                end
                hdr.mapInfo = info;
                
                % compute the coordinates of each pixel
                % code from ftp://ftp.shef.ac.uk/pub/uni/projects/ctcd/MartinWhittle/ForestWeb/MatlabProcessing/EnviToMatlab
                xi = info.xReferencePixelLocation;
                yi = info.yReferencePixelLocation;
                xm = info.pixelEasting;
                ym = info.pixelNorthing;
                %adjust points to corner (1.5,1.5)
                if yi > 1.5 
                    ym = ym + ( ( yi * info.yPixelSize ) - info.yPixelSize );
                end
                if xi > 1.5 
                    xm = xm - ( ( xi * info.xPixelSize ) - info.xPixelSize );
                end

                hdr.xLoc = xm + ( ( 0:hdr.samples - 1 ) .* ...
                    info.xPixelSize );
                hdr.yLoc = fliplr( ym - ( ( 0:hdr.lines - 1 ) .* ... 
                    info.yPixelSize ) );
          
            case 'samples'
                hdr.samples = str2double( hdr.other( idx ).value );
                hdr.other = removeFromOther( hdr.other, idx );
            case 'sensor type'
                hdr.sensorType = hdr.other( idx ).value;
                hdr.other = removeFromOther( hdr.other, idx );
            case 'wavelength'
                hdr.wavelength = ...
                    parseCommaSeparatedDouble( hdr.other( idx ).value );
                hdr.other = removeFromOther( hdr.other, idx );
            case 'wavelength units'
                hdr.wavelengthUnits = ...
                    parseCommaSeparatedValues( hdr.other( idx ).value );
                hdr.other = removeFromOther( hdr.other, idx );
            case 'x start'
                hdr.xStart = str2double( hdr.other( idx ).value );
                hdr.other = removeFromOther( hdr.other, idx );
            case 'y start'
                hdr.yStart = str2double( hdr.other( idx ).value );
                hdr.other = removeFromOther( hdr.other, idx );
            otherwise
                idx = idx + 1;
        end
    end
    if numel( hdr.other ) == 0
        % if all of the keys in header have been parsed, we can remove the
        % other field.
         hdr = rmfield( hdr, 'other' );
    end
end

function [ key, value ] = readENVIheaderLine( fid )
    line = fgetl( fid );
    [ key, line ] = parseEquals( line );
    
    % removes white space and makes the text all lower case which was 
    % causing errors
    key = lower( strtrim( key ) ); 
    
    % read the values
    loc = strfind( line, '{' );
    
    if ( numel( loc ) > 0 )
        % we may be on multiple lines
        nrightbracket = 0;
        nleftbracket = numel( loc );
        value = '';
        
        % remove the first bracket
        line = line( loc( 1 ) + 1:end );
        
        while ( nrightbracket < nleftbracket )
            loc =  strfind( line, '}' );
            nrightbracket = nrightbracket + numel( loc );
            if ( nrightbracket < nleftbracket ) 
                % we have not found all of the end
                value = strcat( value, line );
                % read another line

                line = fgetl( fid ); 
                % check to see if we have more opening brackets
                loc = strfind( line, '{' );
                nleftbracket = nleftbracket + numel( loc );
            else
                % we have found the end, remove the last bracekt
                value = strcat( value, line( 1:loc( end ) - 1 ) );
            end
        end
    else
        value = line;
    end 
    value = strtrim( value );
end

function other = removeFromOther( other, i )
    idx = 1:numel( other );
    idx = ( idx ~= i );
    other = other( idx );
end

function data = parseCommaSeparatedDouble( line )
    data = str2double( parseCommaSeparatedValues( line ) );
end

function data = parseCommaSeparatedValues( line )
    loc = [ 0, strfind( line, ',' ), numel( line ) + 1 ];
    data{ numel( loc ) - 1 } = '';
    for i = 1:numel( loc ) - 1
        data{ i } = strtrim( line( loc( i ) + 1:loc( i + 1 ) - 1 ) );
    end
end

function [ key, data ] = parseEquals( line )
    loc = strfind( line, '=' );
    if numel( loc ) == 0
        % we have no equals, set key to line and data to a blank string
        key = line;
        data = '';
    else
        key = strtrim( line( 1:loc( 1 ) - 1 ) );
        data = strtrim( line( loc( 1 ) + 1:end ) );
    end
end


% get the MATLAB data type name for the ENVI data type
function [ dataTypeName, isComplex ] = convertDataType( dataType )
    isComplex = false;
    switch dataType
        case 1
            dataTypeName = 'uint8';
        case 2
            dataTypeName = 'int16';
        case 3
            dataTypeName = 'int32';
        case 4
            dataTypeName = 'single';
        case 5
            dataTypeName = 'double';
        case 6
            dataTypeName = 'single';
            isComplex = true;
        case 9
            dataTypeName = 'double';
            isComplex = true;
        case 12
            dataTypeName = 'uint16';
        case 13
            dataTypeName = 'uint32';
        case 14
            dataTypeName = 'int64';
        case 15
            dataTypeName = 'uint64';
        otherwise
             error( 'readenvi:convertDataType:unknownDataType', ...
                 'Unknown image data type');
    end
end


% force the image to be the right data type!
function A = makeImageRightType( A, dataTypeNum )
    switch dataTypeNum
        case 1
            A = uint8( A );
        case 2
            A = int16( A );
        case 3
            A = int32( A );
        case 4
            A = single( A );
        case 5
            A = double( A );
        case 6
            A = single( A );
            warning( 'readenvi:makeImageRightType:complex', ...
                'Complex data is NOT formatted properly' );
        case 9
            A = double( A );
            warning( 'readenvi:makeImageRightType:complex', ...
                'Complex data is NOT formatted properly' );
        case 12
            A = uint16( A );
        case 13
            A = uint32( A );
        case 14
            A = int64( A );
        case 15
            A = uint64( A );
        otherwise
             error( 'readenvi:makeImageRightType:unknownDataType', ...
                 'Unknown image data type');
    end
end