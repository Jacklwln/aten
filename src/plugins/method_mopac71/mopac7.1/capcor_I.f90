      MODULE capcor_I   
      INTERFACE
!...Generated by Pacific-Sierra Research 77to90  4.4G  10:47:02  03/09/06  
      REAL(KIND(0.0D0)) FUNCTION capcor (NAT, NFIRST, NLAST,  P, H) 
      USE vast_kind_param,ONLY: DOUBLE 
      use molkst_C, only : numat
      INTEGER, DIMENSION(NUMAT), INTENT(IN) :: NAT 
      INTEGER, DIMENSION(NUMAT), INTENT(IN) :: NFIRST 
      INTEGER, DIMENSION(NUMAT), INTENT(IN) :: NLAST  
      REAL(DOUBLE), DIMENSION(*), INTENT(IN) :: P 
      REAL(DOUBLE), DIMENSION(*), INTENT(IN) :: H 
      END FUNCTION  
      END INTERFACE 
      END MODULE 
