      MODULE nonbet_I   
      INTERFACE
!...Generated by Pacific-Sierra Research 77to90  4.4G  21:23:38  03/14/06  
      SUBROUTINE nonbet (U1X, U1Y, U1Z, U2X, U2Y, U2Z, G1X, G1Y, G1Z, G2X, G2Y&
        , G2Z) 
      USE vast_kind_param,ONLY: DOUBLE 
      use molkst_C, only : norbs
      real(DOUBLE), DIMENSION(norbs,norbs) :: U1X 
      real(DOUBLE), DIMENSION(norbs,norbs) :: U1Y 
      real(DOUBLE), DIMENSION(norbs,norbs) :: U1Z 
      real(DOUBLE), DIMENSION(norbs,norbs) :: U2X 
      real(DOUBLE), DIMENSION(norbs,norbs) :: U2Y 
      real(DOUBLE), DIMENSION(norbs,norbs) :: U2Z 
      real(DOUBLE), DIMENSION(norbs,norbs) :: G1X 
      real(DOUBLE), DIMENSION(norbs,norbs) :: G1Y 
      real(DOUBLE), DIMENSION(norbs,norbs) :: G1Z 
      real(DOUBLE), DIMENSION(norbs,norbs) :: G2X 
      real(DOUBLE), DIMENSION(norbs,norbs) :: G2Y 
      real(DOUBLE), DIMENSION(norbs,norbs) :: G2Z 
      END SUBROUTINE  
      END INTERFACE 
      END MODULE 
