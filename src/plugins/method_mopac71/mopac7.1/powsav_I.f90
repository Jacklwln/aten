      MODULE powsav_I   
      INTERFACE
!...Generated by Pacific-Sierra Research 77to90  4.4G  10:47:34  03/09/06  
      SUBROUTINE powsav (HESS, GRAD, XPARAM, PMAT, ILOOP, BMAT, IPOW) 
      USE vast_kind_param,ONLY: DOUBLE 
      use molkst_C, only : nvar
      REAL(DOUBLE), DIMENSION(NVAR,NVAR), INTENT(IN) :: HESS 
      REAL(DOUBLE), DIMENSION(NVAR), INTENT(IN) :: GRAD 
      REAL(DOUBLE), DIMENSION(NVAR), INTENT(IN) :: XPARAM 
      REAL(DOUBLE), DIMENSION(*), INTENT(IN) :: PMAT 
      INTEGER, INTENT(INOUT) :: ILOOP 
      REAL(DOUBLE), DIMENSION(NVAR,NVAR), INTENT(IN) :: BMAT 
      INTEGER, DIMENSION(9), INTENT(IN) :: IPOW 
      END SUBROUTINE  
      END INTERFACE 
      END MODULE 
