/***************************************************************************
                          coplanar.cpp  -  description
                             -------------------
    begin                : Sat Aug 23 2003
    copyright            : (C) 2003 by Michael Margraf
    email                : margraf@mwt.ee.tu-berlin.de
 ***************************************************************************/

/***************************************************************************
 *                                                                         *
 *   This program is free software; you can redistribute it and/or modify  *
 *   it under the terms of the GNU General Public License as published by  *
 *   the Free Software Foundation; either version 2 of the License, or     *
 *   (at your option) any later version.                                   *
 *                                                                         *
 ***************************************************************************/

#include "coplanar.h"


Coplanar::Coplanar()
{
  Description = "coplanar line";

  Lines.append(new Line(-30,  0,-18,  0,QPen(QPen::darkBlue,2)));
  Lines.append(new Line( 18,  0, 30,  0,QPen(QPen::darkBlue,2)));
  Lines.append(new Line(-13, -8, 23, -8,QPen(QPen::darkBlue,2)));
  Lines.append(new Line(-23,  8, 13,  8,QPen(QPen::darkBlue,2)));
  Lines.append(new Line(-13, -8,-23,  8,QPen(QPen::darkBlue,2)));
  Lines.append(new Line( 23, -8, 13,  8,QPen(QPen::darkBlue,2)));

  Lines.append(new Line(-25,-13, 25,-13,QPen(QPen::darkBlue,2)));
  Lines.append(new Line( 16,-21, 24,-13,QPen(QPen::darkBlue,2)));
  Lines.append(new Line(  8,-21, 16,-13,QPen(QPen::darkBlue,2)));
  Lines.append(new Line(  0,-21,  8,-13,QPen(QPen::darkBlue,2)));
  Lines.append(new Line( -8,-21,  0,-13,QPen(QPen::darkBlue,2)));
  Lines.append(new Line(-16,-21, -8,-13,QPen(QPen::darkBlue,2)));
  Lines.append(new Line(-24,-21,-16,-13,QPen(QPen::darkBlue,2)));
  
  Lines.append(new Line(-25, 13, 25, 13,QPen(QPen::darkBlue,2)));
  Lines.append(new Line(-24, 13,-16, 21,QPen(QPen::darkBlue,2)));
  Lines.append(new Line(-16, 13, -8, 21,QPen(QPen::darkBlue,2)));
  Lines.append(new Line( -8, 13,  0, 21,QPen(QPen::darkBlue,2)));
  Lines.append(new Line(  0, 13,  8, 21,QPen(QPen::darkBlue,2)));
  Lines.append(new Line(  8, 13, 16, 21,QPen(QPen::darkBlue,2)));
  Lines.append(new Line( 16, 13, 24, 21,QPen(QPen::darkBlue,2)));

  Ports.append(new Port(-30, 0));
  Ports.append(new Port( 30, 0));

  x1 = -30; y1 =-24;
  x2 =  30; y2 = 24;

  tx = x1+4;
  ty = y2+4;
  Sign  = "CLIN";
  Model = "CLIN";
  Name  = "CL";

  Props.append(new Property("Subst", "Subst1", true, "name of substrate definition"));
  Props.append(new Property("W", "1 mm", true, "width of the line"));
  Props.append(new Property("S", "1 mm", true, "width of a gap"));
  Props.append(new Property("L", "10 mm", true, "length of the line"));
//  Props.append(new Property("Model", "Kirschning", false, "microstrip model |Kirschning|Kobayashi|Yamashita"));
}

Coplanar::~Coplanar()
{
}

Coplanar* Coplanar::newOne()
{
  return new Coplanar();
}
