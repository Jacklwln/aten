      subroutine dihed(xyz, i, j, k, l, angle) 
!-----------------------------------------------
!   M o d u l e s 
!-----------------------------------------------
      USE vast_kind_param, ONLY:  double 
!...Translated by Pacific-Sierra Research 77to90  4.4G  10:47:09  03/09/06  
!...Switches: -rl INDDO=2 INDIF=2 
!-----------------------------------------------
!   I n t e r f a c e   B l o c k s
!-----------------------------------------------
      use dang_I 
      implicit none
!-----------------------------------------------
!   D u m m y   A r g u m e n t s
!-----------------------------------------------
      integer , intent(in) :: i 
      integer , intent(in) :: j 
      integer , intent(in) :: k 
      integer , intent(in) :: l 
      real(double)  :: angle 
      real(double) , intent(in) :: xyz(3,*) 
!-----------------------------------------------
!   L o c a l   V a r i a b l e s
!-----------------------------------------------
      real(double) :: xi1, xj1, xl1, yi1, yj1, yl1, zi1, zj1, zl1, dist, cosa, &
        ddd, yxdist, xi2, xl2, yi2, yl2, costh, sinth, cosph, sinph, yj2, yi3, &
        yl3 
!-----------------------------------------------
!********************************************************************
!
!      DIHED CALCULATES THE DIHEDRAL ANGLE BETWEEN ATOMS I, J, K,
!            AND L.  THE CARTESIAN COORDINATES OF THESE ATOMS
!            ARE IN ARRAY XYZ.
!
!     DIHED IS A MODIFIED VERSION OF A SUBROUTINE OF THE SAME NAME
!           WHICH WAS WRITTEN BY DR. W. THEIL IN 1973.
!
!********************************************************************
      xi1 = xyz(1,i) - xyz(1,k) 
      xj1 = xyz(1,j) - xyz(1,k) 
      xl1 = xyz(1,l) - xyz(1,k) 
      yi1 = xyz(2,i) - xyz(2,k) 
      yj1 = xyz(2,j) - xyz(2,k) 
      yl1 = xyz(2,l) - xyz(2,k) 
      zi1 = xyz(3,i) - xyz(3,k) 
      zj1 = xyz(3,j) - xyz(3,k) 
      zl1 = xyz(3,l) - xyz(3,k) 
!      ROTATE AROUND Z AXIS TO PUT KJ ALONG Y AXIS
      dist = sqrt(xj1*xj1 + yj1*yj1 + zj1*zj1) 
      cosa = zj1/dist 
      cosa = min(1.0D0,cosa) 
      cosa = dmax1(-1.0D0,cosa) 
      ddd = 1.0D0 - cosa**2 
      if (ddd <= 0.0D0) go to 10 
      yxdist = dist*sqrt(ddd) 
      if (yxdist > 1.0D-6) go to 20 
   10 continue 
      xi2 = xi1 
      xl2 = xl1 
      yi2 = yi1 
      yl2 = yl1 
      costh = cosa 
      sinth = 0.D0 
      go to 30 
   20 continue 
      cosph = yj1/yxdist 
      sinph = xj1/yxdist 
      xi2 = xi1*cosph - yi1*sinph 
      xl2 = xl1*cosph - yl1*sinph 
      yi2 = xi1*sinph + yi1*cosph 
      yj2 = xj1*sinph + yj1*cosph 
      yl2 = xl1*sinph + yl1*cosph 
!      ROTATE KJ AROUND THE X AXIS SO KJ LIES ALONG THE Z AXIS
      costh = cosa 
      sinth = yj2/dist 
   30 continue 
      yi3 = yi2*costh - zi1*sinth 
      yl3 = yl2*costh - zl1*sinth 
      call dang (xl2, yl3, xi2, yi3, angle) 
!     6.2831853  IS 2 * 3.1415926535 = 180 DEGREE
      if (angle < 0.) angle = 6.28318530717959D0 + angle 
      if (angle >= 6.28318530717959D0) angle = 0.D0 
      return  
      end subroutine dihed 
