      subroutine mecid(eigs, gse, eiga, diag, xy) 
!-----------------------------------------------
!   M o d u l e s 
!-----------------------------------------------
      USE vast_kind_param, ONLY:  double 
      use meci_C, only : occa, microa, microb, nmos, lab
!***********************************************************************
!DECK MOPAC
!...Translated by Pacific-Sierra Research 77to90  4.4G  10:47:24  03/09/06  
!...Switches: -rl INDDO=2 INDIF=2 
!-----------------------------------------------
!   I n t e r f a c e   B l o c k s
!-----------------------------------------------
      use diagi_I 
      implicit none
!-----------------------------------------------
!   D u m m y   A r g u m e n t s
!-----------------------------------------------
      real(double) , intent(out) :: gse 
      real(double) , intent(in) :: eigs(*) 
      real(double)  :: eiga(*) 
      real(double) , intent(out) :: diag(*) 
      real(double)  :: xy(nmos,nmos,nmos,nmos) 
!-----------------------------------------------
!   L o c a l   P a r a m e t e r s
!-----------------------------------------------
!-----------------------------------------------
!   L o c a l   V a r i a b l e s
!-----------------------------------------------
      integer :: i, j 
      real(double) :: x 
!-----------------------------------------------
!***********************************************************************
!
!   MECID CALCULATES THE EFFECT OF REMOVING THE ELECTRONS INVOLVED IN
!   THE C.I. FROM THE GROUND-STATE CONFIGURATION, AND CALCULATES THE
!   MICROSTATE ENERGIES OF THE MICROSTATES INVOLVED IN THE C.I.
!
!  THE QUANTITIES NMOS, NELEC, AND LAB, AND THE ARRAYS EIGS, OCCA,
!  MICROA, AND MICROB ARE USED, BUT UNCHANGED ON EXIT
!
!   ON EXIT, GSE IS THE ELECTRONIC ENERGY OF STABILIZATION DUE TO
!            REMOVAL OF THE ELECTRONS INVOLVED IN THE C.I.
!
!            EIGA HOLDS THE ONE-ELECTRON ENERGY LEVELS RESULTING FROM
!            REMOVAL OF THE ELECTRONS INVOLVED IN THE C.I.
!
!            DIAG HOLDS THE MICROSTATE ENERGIES OF ALL STATES INVOLVED
!            IN THE C.I.  THIS CAN BE USED AS THE DIAGONAL OF A C.I.
!            MATRIX
!
!***********************************************************************
      gse = 0.D0 
      do i = 1, nmos 
        x = 0.D0 
        do j = 1, nmos 
          x = x + (2.D0*xy(i,i,j,j)-xy(i,j,i,j))*occa(j) 
        end do 
        eiga(i) = eigs(i) - x 
        gse = gse + eiga(i)*occa(i)*2.D0 
        gse = gse + xy(i,i,i,i)*occa(i)*occa(i) 
        do j = i + 1, nmos 
          gse = gse + 2.D0*(2.D0*xy(i,i,j,j)-xy(i,j,i,j))*occa(i)*occa(j) 
        end do 
      end do 
      do i = 1, lab 
        diag(i) = diagi(microa(1,i),microb(1,i),eiga,xy,nmos) - gse 
      end do 
      return  
      end subroutine mecid 
