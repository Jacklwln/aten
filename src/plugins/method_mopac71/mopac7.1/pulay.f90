      subroutine pulay(f, p, n, fppf, fock, emat, lfock, nfock, msize, start, &
        pl) 
!-----------------------------------------------
!   M o d u l e s 
!-----------------------------------------------
      USE vast_kind_param, ONLY:  double 
      use chanel_C, only : iw
      use molkst_C, only : numcal, keywrd, mpack
!...Translated by Pacific-Sierra Research 77to90  4.4G  11:04:59  03/09/06  
!...Switches: -rl INDDO=2 INDIF=2 
!-----------------------------------------------
!   I n t e r f a c e   B l o c k s
!-----------------------------------------------
      use mamult_I 
      use dot_I 
      use osinv_I 
      implicit none
!-----------------------------------------------
!   D u m m y   A r g u m e n t s
!-----------------------------------------------
      integer  :: n 
      integer , intent(inout) :: lfock 
      integer , intent(inout) :: nfock 
      integer , intent(in) :: msize 
      real(double) , intent(out) :: pl 
      logical , intent(inout) :: start 
      real(double)  :: f(mpack) 
      real(double)  :: p(mpack) 
      real(double)  :: fppf(*) 
      real(double) , intent(inout) :: fock(*) 
      real(double) , intent(inout) :: emat(20,20) 
!-----------------------
!   L o c a l   V a r i a b l e s
!-----------------------------------------------
      integer :: icalcn, maxlim, linear, mfock, lbase, i, nfock1, j, l, il&
        , ii 
      real(double), dimension(1000) :: evec 
      real(double), dimension(20) :: coeffs 
      real(double) :: const, d, sum 
      logical :: debug 

      save icalcn, maxlim, debug, linear, mfock 
!-----------------------------------------------
!***********************************************************************
!
!   PULAY USES DR. PETER PULAY'S METHOD FOR CONVERGENCE.
!         A MATHEMATICAL DESCRIPTION CAN BE FOUND IN
!         "P. PULAY, J. COMP. CHEM. 3, 556 (1982).
!
! ARGUMENTS:-
!         ON INPUT F      = FOCK MATRIX, PACKED, LOWER HALF TRIANGLE.
!                  P      = DENSITY MATRIX, PACKED, LOWER HALF TRIANGLE.
!                  N      = NUMBER OF ORBITALS.
!                  FPPF   = WORKSTORE OF SIZE MSIZE, CONTENTS WILL BE
!                           OVERWRITTEN.
!                  FOCK   =      "       "              "         "
!                  EMAT   = WORKSTORE OF AT LEAST 20**2 ELEMENTS.
!                  START  = LOGICAL, = TRUE TO START PULAY.
!                  PL     = UNDEFINED ELEMENT.
!      ON OUTPUT   F      = "BEST" FOCK MATRIX, = LINEAR COMBINATION
!                           OF KNOWN FOCK MATRICES.
!                  START  = FALSE
!                  PL     = MEASURE OF NON-SELF-CONSISTENCY
!                         = [F*P] = F*P - P*F.
!
!***********************************************************************
      data icalcn/ 0/  
      if (icalcn /= numcal) then 
        icalcn = numcal 
        maxlim = 6 
        debug = index(keywrd,'DEBUGPULAY') /= 0 
      endif 
      if (start) then 
        linear = (n*(n + 1))/2 
        mfock = msize/linear 
        mfock = min0(maxlim,mfock) 
        if (debug) write (iw, '('' MAXIMUM SIZE:'',I5)') mfock 
        nfock = 1 
        lfock = 1 
        start = .FALSE. 
      else 
        if (nfock < mfock) nfock = nfock + 1 
        if (lfock /= mfock) then 
          lfock = lfock + 1 
        else 
          lfock = 1 
        endif 
      endif 
      lbase = (lfock - 1)*linear 
!
!   FIRST, STORE FOCK MATRIX FOR FUTURE REFERENCE.
!
      fock(lfock:(linear-1)*mfock+lfock:mfock) = f(:linear) 
!
!   NOW FORM /FOCK*DENSITY-DENSITY*FOCK/, AND STORE THIS IN FPPF
!
      call mamult (p, f, fppf(lbase+1), n, 0.D0) 
      call mamult (f, p, fppf(lbase+1), n, -1.D0) 
!
!   FPPF NOW CONTAINS THE RESULT OF FP - PF.
!
      nfock1 = nfock + 1 
      do i = 1, nfock 
        emat(nfock1,i) = -1.D0 
        emat(i,nfock1) = -1.D0 
        emat(lfock,i) = dot(fppf((i-1)*linear+1),fppf(lbase+1),linear) 
        emat(i,lfock) = emat(lfock,i) 
      end do 
      pl = emat(lfock,lfock)/linear 
      emat(nfock1,nfock1) = 0.D0 
      const = 1.D0/emat(lfock,lfock) 
      emat(:nfock,:nfock) = emat(:nfock,:nfock)*const 
      if (debug) then 
        write (iw, '('' EMAT'')') 
        do i = 1, nfock1 
          write (iw, '(6E13.6)') (emat(j,i),j=1,nfock1) 
        end do 
      endif 
      l = 0 
      do i = 1, nfock1 
        evec(l+1:nfock1+l) = emat(i,:nfock1) 
        l = nfock1 + l 
      end do 
      const = 1.D0/const 
      emat(:nfock,:nfock) = emat(:nfock,:nfock)*const 
!********************************************************************
!   THE MATRIX EMAT SHOULD HAVE FORM
!
!      |<E(1)*E(1)>  <E(1)*E(2)> ...   -1.0|
!      |<E(2)*E(1)>  <E(2)*E(2)> ...   -1.0|
!      |<E(3)*E(1)>  <E(3)*E(2)> ...   -1.0|
!      |<E(4)*E(1)>  <E(4)*E(2)> ...   -1.0|
!      |     .            .      ...     . |
!      |   -1.0         -1.0     ...    0. |
!
!   WHERE <E(I)*E(J)> IS THE SCALAR PRODUCT OF [F*P] FOR ITERATION I
!   TIMES [F*P] FOR ITERATION J.
!
!********************************************************************
      call osinv (evec, nfock1, d) 
      if (abs(d) < 1.D-6) then 
        start = .TRUE. 
        return  
      endif 
      if (nfock < 2) return  
      il = nfock*nfock1 
      coeffs(:nfock) = -evec(1+il:nfock+il) 
      if (debug) then 
        write (iw, '('' EVEC'')') 
        write (iw, '(6F12.6)') (coeffs(i),i=1,nfock) 
        write (iw, &
      '(''    LAGRANGIAN MULTIPLIER (ERROR) =''                          ,F13.6&
      &)') evec(nfock1*nfock1) 
      endif 
      do i = 1, linear 
        sum = 0.D0 
        l = 0 
        ii = (i - 1)*mfock 
        do j = 1, nfock 
          sum = sum + coeffs(j)*fock(j+ii) 
        end do 
        f(i) = sum 
      end do 
      return  
      end subroutine pulay 
