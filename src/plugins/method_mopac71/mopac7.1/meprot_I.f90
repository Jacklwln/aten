      MODULE meprot_I   
      INTERFACE
!...Generated by Pacific-Sierra Research 77to90  4.4G  12:03:19  03/10/06  
      SUBROUTINE meprot (C, R0, T, XM, YM, ICASE, STEP, C1, Z0, IBACK) 
      USE vast_kind_param,ONLY: DOUBLE 
      real(DOUBLE), DIMENSION(3,*), INTENT(IN) :: C 
      real(DOUBLE), DIMENSION(3), INTENT(INOUT) :: R0 
      real(DOUBLE), DIMENSION(3,3), INTENT(INOUT) :: T 
      real(DOUBLE), INTENT(OUT) :: XM 
      real(DOUBLE), INTENT(OUT) :: YM 
      integer, INTENT(IN) :: ICASE 
      real(DOUBLE), INTENT(IN) :: STEP 
      real(DOUBLE), DIMENSION(3,*), INTENT(OUT) :: C1 
      real(DOUBLE), INTENT(IN) :: Z0 
      integer, INTENT(OUT) :: IBACK 
      END SUBROUTINE  
      END INTERFACE 
      END MODULE 
