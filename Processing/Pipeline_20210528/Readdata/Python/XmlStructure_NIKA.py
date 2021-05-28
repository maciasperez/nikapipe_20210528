#!/usr/bin/env python

# Copyright (C) 2002
# Max-Planck-Institut fuer Radioastronomie Bonn
#
# Produced for the ALMA and APEX projects
#
# This library is free software; you can redistribute it and/or modify it under
# the terms of the GNU Library General Public License as published by the Free
# Software Foundation; either version 2 of the License, or (at your option) any
# later version.
#
# This library is distributed in the hope that it will be useful, but WITHOUT
# ANY WARRANTY; without even the implied warranty of MERCHANTABILITY FITNESS
# FOR A PARTICULAR PURPOSE. See the GNU Library General Public License for more
# details.
#
# You should have received a copy of the GNU Library General Public License
# along with this library; if not, write to the Free Software Foundation, Inc.,
# 675 Massachusetts Ave, Cambridge, MA 02139, USA.  Correspondence concerning
# ALMA should be addressed as follows:
#
# Internet email: alma-sw-admin@nrao.edu
#
# Correspondence concerning APEX should be addressed as follows:
#
# Internet email: dmuders@mpifr-bonn.mpg.de

# The Python ALMA-TI FITS / APEX MBFITS Raw Data Writer
#
# Who			When		What
#
# C.Koenig, MPIfR       03/20/2003      Seperation of XmlSturucture from MBFits module


""" This is the ALMA-TI FITS / MBFITS XML Tools Library.
(c) 2002-2003 MPIfR """

class XmlStructure:
    def __init__(self,filename):
        self.create(filename)
        
    def create(self,filename):
        from xml.dom.minidom import parse, parseString

        # parse XML file by name
        dom = parse(filename)

        # normalize whitespaces
        dom.documentElement.normalize()

        # first element is the Scan
        XmlScan=dom.documentElement
        
        # scan consists of table- and process-definitions
        #print "Reading XML: "+XmlScan.nodeName
        self.XmlScan=SubStructure(XmlScan)

class SubStructure:

    """ Analyze XML SubStructure """

    def __init__(self,process):
        self.create(process)
    
    def create(self,process):
        # analyze element (elements can have elements(nodeType 1),
	# attributes (nodeType 2), text (nodeType 3)
        if process.hasChildNodes():
            self.tables={}
            for element in process.childNodes:
                
                # create tables if one found in process definition
                if element.nodeType == 1 and element.getAttribute('content') == 'table':
                    self.tables[str(element.tagName)]=element
                    #print "..... Table "+element.nodeName+" found in XML."

                # analyse substructure (process-definition) if one is found
                elif element.nodeType == 1 and element.getAttribute('content') == 'process':
                    struc=SubStructure(element)
                    for key in struc.tables.keys():
                        self.tables[key]=struc.tables[key]


# including the fits_writer module automaticaly creates the XmlStruc object instance
# global configuration file
##XmlStruc=XmlStructure('/ncsServer/mrt/ncs/configuration/IMBFits/IMBFits_NIKA.xml')
# local file for debugging
XmlStruc=XmlStructure('IMBFits_NIKA.xml')
