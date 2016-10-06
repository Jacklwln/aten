      real(kind(0.0d0)) function babbbc (iocca1, ioccb1, ioccb2, nmos, xy) 
!-----------------------------------------------
!   M o d u l e s 
!-----------------------------------------------
      USE vast_kind_param, ONLY:  double 
      use meci_C, only : occa
!***********************************************************************
!DECK MOPAC
!...Translated by Pacific-Sierra Research 77to90  4.4G  10:47:01  03/09/06  
!...Switches: -rl INDDO=2 INDIF=2 
      implicit none
!-----------------------------------------------
!   G l o b a l   P a r a m e t e r s
!-----------------------------------------------
!-----------------------------------------------
!   D u m m y   A r g u m e n t s
!-----------------------------------------------
      integer , intent(in) :: nmos 
      integer , intent(in) :: iocca1(nmos) 
      integer , intent(in) :: ioccb1(nmos) 
      integer , intent(in) :: ioccb2(nmos) 
      real(double) , intent(in) :: xy(nmos,nmos,nmos,nmos) 
!-----------------------------------------------
!   L o c a l   V a r i a b l e s
!-----------------------------------------------
      integer :: i, ij, j, k 
      real(double) :: sum 
!-----------------------------------------------
!**********************************************************************
!
! BABBBC EVALUATES THE C.I. MATRIX ELEMENT FOR TWO MICROSTATES DIFFERING
!       BY ONE BETA ELECTRON. THAT IS, ONE MICROSTATE HAS A BETA
!       ELECTRON IN PSI(I) AND THE OTHER MICROSTATE HAS AN ELECTRON IN
!       PSI(J).
!**********************************************************************
      do i = 1, nmos 
        if (ioccb1(i) == ioccb2(i)) cycle  
        exit  
      end do 
      ij = 0 
      do j = i + 1, nmos 
        if (ioccb1(j) /= ioccb2(j)) exit  
        ij = ij + iocca1(j) + ioccb1(j) 
      end do 
      ij = ij + iocca1(j) 
!
!   THE UNPAIRED M.O.S ARE I AND J
      sum = 0.D0 
      do k = 1, nmos 
        sum = sum + (xy(i,j,k,k)-xy(i,k,j,k))*(ioccb1(k)-occa(k)) + xy(i,j,k,k)&
          *(iocca1(k)-occa(k)) 
      end do 
      if (mod(ij,2) == 1) sum = -sum 
      babbbc = sum 
      return  
      end function babbbc 
