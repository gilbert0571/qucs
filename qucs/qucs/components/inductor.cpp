/***************************************************************************
                          inductor.cpp  -  description
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

#include "inductor.h"


Inductor::Inductor()
{
  Description = "inductor";

  Arcs.append(new Arc(-17, -6, 13, 13,  0, 16*180,QPen(QPen::darkBlue,2)));
  Arcs.append(new Arc( -6, -6, 13, 13,  0, 16*180,QPen(QPen::darkBlue,2)));
  Arcs.append(new Arc(  5, -6, 13, 13,  0, 16*180,QPen(QPen::darkBlue,2)));
  Lines.append(new Line(-30,  0,-17,  0,QPen(QPen::darkBlue,2)));
  Lines.append(new Line( 17,  0, 30,  0,QPen(QPen::darkBlue,2)));

  Ports.append(new Port(-30,  0));
  Ports.append(new Port( 30,  0));

  x1 = -30; y1 = -10;
  x2 =  30; y2 =   6;

  tx = x1+4;
  ty = y2+4;
  Sign  = "L";
  Model = "L";
  Name  = "L";

  Props.append(new Property("L", "1 nH", true, "inductance in Henry"));
}

Inductor::~Inductor()
{
}

Inductor* Inductor::newOne()
{
  return new Inductor();
}
