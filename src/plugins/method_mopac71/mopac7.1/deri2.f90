      subroutine deri2(minear, f, fd, fci, ninear, nvar_nvo, dxyzr,  throld, diag, scalar) 
!-----------------------------------------------
!   M o d u l eigs s 
!-----------------------------------------------
      USE vast_kind_param, ONLY:  double  
      USE funcon_C, only : fpc_9
      USE meci_C, only : mmci, nelec, nstate, lab, nmeci, nmos, xy, &
      & vectci, maxci
      USE molkst_C, only : keywrd, mpack, numcal, norbs
      USE chanel_C, only : iw
      use permanent_arrays, only : c, w, eigs
!-----------------------------------------------
!   I n t eigs r f a c eigs   B l o c k s
!-----------------------------------------------
      use second_I 
  !    use deri21_I 
      use deri22_I 
      use mxm_I 
      use osinv_I 
      use mtxm_I 
      use mxmt_I 
      use dcopy_I 
      use mopend_I 
      use deri23_I 
    !  use dijkl2_I 
      use mecid_I 
      use mecih_I 
      use supdot_I 
      use dot_I 
      implicit none
!-----------------------------------------------
!   D u m m y   A r g u m e n t s
!-----------------------------------------------
      integer  :: minear 
      integer  :: ninear 
      integer  :: nvar_nvo
      real(double) , intent(in) :: throld  
      real(double)  :: f(minear,nvar_nvo) 
      real(double)  :: fd(ninear,nvar_nvo) 
      real(double)  :: fci(ninear,nmeci*(nmeci + 1)*10/ninear) 
      real(double)  :: work(minear*norbs) 
      real(double), dimension(:,:), allocatable  :: b, ab, fb
      real(double) , intent(inout) :: dxyzr(nvar_nvo) 
      real(double)  :: diag(mpack) 
      real(double)  :: scalar(mpack) 
      real(double)  :: bab(mmci,mmci) 
      real(double)  :: babinv(mmci*mmci) 
      real(double)  :: bcoef(400) 
!-----------------------------------------------
!   L o c a l   P a r a m e t e r s
!-----------------------------------------------
!-----------------------------------------------
!   L o c a l   V a r i a b l e s
!-----------------------------------------------
      integer :: icalcn, maxite, ifirst, i, nbsize, ilast, j, l, &
        nres, ivar, nadd, nbsze, k, ll, iindex, jindex
      real(double) :: const, time1, deter, test2, test, time2, sum, gse
      logical , dimension(nvar_nvo) :: lconv 
      logical :: fail, debug, lbab 

      save debug, icalcn, maxite, ifirst 
!-----------------------------------------------
!********************************************************************
!
!     DERI2 COMPUTE THE RELAXATION PART OF THE DERIVATIVES OF THE
!     NON-VARIATIONALLY OPTIMIZED ENERGY WITH RESPECT TO TWO
!     COORDINATES AT A TIME. THIS IS DONE IN THREE STEPS.
!
!     THE M.O DERIVATIVES ARE SOLUTION [X] OF A LINEAR SYSTEM
!                        (D-A) * X = F
!     WHERE D IS A DIAGONAL SUPER-MATRIX OF FOCK EIGENVALUE DIFFERENCES
!     AND A IS A SUPER-MATRIX OF 2-ELECTRONS INTEGRALS IN M.O BASIS.
!     SUCH A SYSTEM IS TOO LARGE TO BE INVERTED DIRECTLY THUS ONE MUST
!     USES A RELAXATION METHOD TO GET A REASONABLE ESTIMATE OF [X].
!     THIS REQUIRES A BASIS SET [B] TO BE GENERATED ITERATIVELY, AFTER
!     WHICH WE SOLVE BY DIRECT INVERSION THE LINEAR SYSTEM PROJECTED
!     IN THIS BASIS [B]. IT WORKS QUICKLY BUT DOES REQUIRE A LARGE
!     CORE MEMORY.
!
!     USE A FORMALISM WITH FOCK OPERATOR THUS AVOIDING THE EXPLICIT
!     COMPUTATION (AND STORAGE) OF THE SUPER-MATRIX A.
!     THE SEMIEMPIRICAL METHODS DO NOT INVOLVE LARGE C.I CALCULATIONS.
!     THEREFORE FOR EACH GRADIENT COMPONENT WE BUILD THE C.I MATRIX
!     DERIVATIVE FROM THE M.O. INTEGRALS <IJ|KL> AND FOCK EIGENVALUES
!     DERIVATIVES, THUS PROVIDING THE RELAXATION CONTRIBUTION TO THE
!     GRADIENT WITHOUT COMPUTATION AND STORAGE OF THE 2ND ORDER DENSITY
!     MATRIX.
!
!   STEP 1)
!     USE THE PREVIOUS B AND THE NEW F VECTORS TO BUILD AN INITIAL
!     BASIS SET B.
!   STEP 2)
!     BECAUSE THE ELECTRONIC HESSIAN (D-A) IS THE SAME FOR EACH
!     DERIVATIVE, WE ONLY NEED TO ENLARGE ITERATIVELY THE ORTHONORMAL
!     BASIS SET [B] USED TO INVERT THE PROJECTED HESSIAN.
!     (DERIVED FROM THE LARGEST RESIDUAL VECTOR ).
!     THIS SECTION IS CARRIED OUT IN THE DIAGONAL METRIC 'SCALAR'.
!   STEP 3) ... LOOP ON THE GEOMETRIC VARIABLE :
! 3.1 FOR EACH GEOMETRIC VARIABLE, GET THE M.O DERIVATIVES IN A.O.
! 3.2 COMPUTE THE FOCK EIGENVALUES AND 2-ELECTRON INTEGRAL RELAXATION.
! 3.3 BUILD THE ELECTRONIC RELAXATION CONTRIBUTION TO THE C.I MATRIX
!     AND GET THE ASSOCIATED EIGENSTATE DERIVATIVE WITH RESPECT TO
!     THE GEOMETRIC VARIABLE.
!
!   INPUT
!     C(NORBS,NORBS) : M.O. COEFFICIENTS, IN COLUMN.
!     eigs(NORBS)       : EIGENVALUES OF THE FOCK MATRIX.
!     MINEAR         : NUMBER OF NON REDUNDANT ROTATION OF THE M.O.
!     F(MINEAR,nvar_nvo) : NON-RELAXED FOCK MATRICES DERIVATIVES
!                    IN M.O BASIS, OFF-DIAGONAL BLOCKS.
!     FD(NINEAR,nvar_nvo): IDEM, DIAGONAL BLOCKS, C.I-ACTIVE ONLY.
!     WORK           : WORK ARRAY OF SIZE N*N.
!     B(MINEAR,NBSIZE) : INITIAL ORTHONORMALIZED BASIS SET [B].
!     dxyzr(nvar_nvo)     : GRADIENT VECTOR BEFORE RELAXATION CORRECTION.
!     AB(MINEAR,*): STORAGE FOR THE (D-A) * B VECTORS.
!     FB(nvar_nvo,*)  : STORAGE FOR THE MATRIX PRODUCT F' * B.
!   OUTPUT
!     dxyzr   : DERIVATIVE OF THE HEAT OF FORMATION WITH RESPECT TO
!              THE nvar_nvo OPTIMIZED VARIABLES.
!
!***********************************************************************
      data icalcn/ 0/  
      save :: b, ab, fb
!
!     * * * STEP 1 * * *
!     BUILD UP THE INITIAL ORTHONORMALIZED BASIS.
!
      if (icalcn /= numcal) then 
        debug = index(keywrd,' DERI2') /= 0 
        const = fpc_9 
        icalcn = numcal 
        maxite = min(min(60,int(sqrt(dble(nmeci**3)))),10000*2/nvar_nvo) 
        ifirst = min(nvar_nvo,1 + maxite/4) 
        k = max((lab*(lab + 1))/2, 20*mpack)
        if (allocated(b))  deallocate(b)
        if (allocated(ab)) deallocate(ab)
        if (allocated(fb)) deallocate(fb)
        i = max(k, (maxci*(maxci + 1))/2)
        allocate(b(minear,i/minear))
        i = max(ninear, i/minear)
        allocate(fb(1,i))
        i = max(20*minear, i)
        allocate(ab(minear, i/minear))  
      endif 
      fail = .FALSE. 
      nbsize = 0 
      if (debug) time1 = second(1) 
!
!        NORMAL CASE. USE F ONLY.
!
      call deri21 (f, nvar_nvo, minear, ifirst, work, work(nvar_nvo*nvar_nvo+1), b, ilast&
        ) 
      lbab = .FALSE. 
      ifirst = nbsize + 1 
      ilast = nbsize + ilast 
      lconv(:nvar_nvo) = .FALSE. 
!
!     * * * STEP 2 * * *
!     RELAXATION METHOD WITH OPTIMUM INCREASE OF THE BASIS SET.
!     ---------------------------------------------------------
!
!     UPDATE AB ,FCI AND BAB. (BAB IS SYMMETRIC)
   30 continue 
      do j = ifirst, ilast 
        call deri22 (c, b(1,j), work, work, ab(1,j), minear, fci(1,j), w&
          , diag, scalar, ninear) 
        call mxm (ab(1,j), 1, b, minear, bab(1,j), ilast) 
        bab(j,:ifirst-1) = bab(:ifirst-1,j) 
      end do 
!     INVERT BAB, STORE IN BABINV.
   50 continue 
      l = 0 
      do j = 1, ilast 
        babinv(l+1:ilast+l) = bab(:ilast,j) 
        l = ilast + l 
      end do 
      call osinv (babinv, ilast, deter) 
      if (Abs(deter) < 1.d-20) then 
        if (ilast /= 1) write (iw, &
      '('' THE BAB MATRIX OF ORDER'',I3,                    '' IS SINGULAR IN D&
      &ERI2''/                                        '' THE RELAXATION IS STOPP&
      &ED AT THIS POINT.'')') ilast 
        lbab = .TRUE. 
        ilast = ilast - 1 
        go to 50 
      endif 
!        UPDATE F * B'
      if (.not.lbab) call mtxm (f, nvar_nvo, b(1,ifirst), minear, fb(1,ifirst), &
        ilast - ifirst + 1) 
!     NEW SOLUTIONS IN BASIS B , STORED IN BCOEF(nvar_nvo,*).
!     BCOEF = BABINV * FB'
      if (ilast /= 0) call mxmt (babinv, ilast, fb, ilast, bcoef, nvar_nvo) 
      if (lbab) go to 100 
!
!     SELECT THE NEXT BASIS VECTOR AS THE LARGEST RESIDUAL VECTOR.
!     AND TEST FOR CONVERGENCE ON THE LARGEST RESIDUE.
      nres = 0 
      test2 = 0.D0 
      do ivar = 1, nvar_nvo 
        if (lconv(ivar)) cycle  
!     GET ONE NOT-CONVERGED RESIDUAL VECTOR (# IVAR),
!     STORED IN WORK.
        call mxm (ab, minear, bcoef(ilast*(ivar-1)+1), ilast, work, 1) 
        test = 0.D0 
        do i = 1, minear 
          work(i) = f(i,ivar) - work(i) 
          test = max(abs(work(i)),test) 
        end do 
        if (debug) write (iw, *) ' TEST:', test 
        test2 = max(test2,test) 
        if (test <= throld) then 
          lconv(ivar) = .TRUE. 
          if (nvar_nvo == 1) go to 100 
          cycle  
        else if (ilast + nres == maxite) then 
!
!   COMPLETELY OUT OF STORAGE
!
          fail = nres == 0 
          exit  
        else if (ilast + nres >= maxite - 1) then 
!        RUNNING OUT OF STORAGE
          if (test <= max(0.01D0,throld*2)) then 
            lconv(ivar) = .TRUE. 
            cycle  
          endif 
        else 
!        STORE THE FOLLOWING RESIDUE IN AB(CONTINUED).
          nres = nres + 1 
          call dcopy (minear, work, 1, ab(1,ilast+nres), 1) 
        endif 
      end do 
      if (nres == 0) go to 100 
!     FIND OPTIMUM FOLLOWING SUBSET, ADD TO B AND LOOP.
      ifirst = ilast + 1 
      call deri21 (ab(1,ifirst), nres, minear, nres, work, work(nres*nres+1)&
        , b(1,ifirst), nadd) 
      ilast = ilast + nadd 
      go to 30 
!
!     CONVERGENCE ACHIEVED OR HALTED.
!     -------------------------------
!
  100 continue 
      nbsze = nbsize 
      if (debug .or. lbab) then 
        write (iw, &
      '('' RELAXATION ENDED IN DERI2 AFTER'',I3,               '' CYCLES''/'' R&
      &EQUIRED CONVERGENCE THRESHOLD ON RESIDUALS =''    ,F12.9/'' HIGHEST RESID&
      &UAL ON'',I3,'' GRADIENT COMPONENTS = ''    ,F12.9)') ilast - nbsze, &
          throld, nvar_nvo, test2 
        if (ilast - nbsze == 0) then 
          write (iw, '(A)') &
            ' ANALYTIC C.I. DERIVATIVES DO NOT WORK FOR THIS SYSTEM' 
          write (iw, '(A)') ' ADD KEYWORD ''NOANCI'' AND RESUBMIT' 
          call mopend (&
       'ANALYTIC C.I. DERIVATIVES DO NOT WORK FOR THIS SYSTEM.  ADD KEYWORD "NOA&
       &NCI" AND RESUBMIT') 
          return  
        endif 
        time2 = second(1) 
        write (iw, &
          '('' ELAPSED TIME IN RELAXATION'',F15.3,'' SECOND'')                '&
          ) time2 - time1 
      endif 
      if (fail) then 
        write (iw, '(A)') ' ANALYTICAL DERIVATIVES TOO INACCURATE FOR THIS' 
        write (iw, '(A)') ' WORK.  JOB STOPPED HERE.  SEE MANUAL FOR IDEAS' 
        call mopend (&
       'ANALYTICAL DERIVATIVES TOO INACCURATE FOR THIS WORK.  JOB STOPPED HERE. &
       & SEE MANUAL FOR IDEAS') 
        return  
      else 
        nbsize = 0 
!        UNSCALED SOLUTION SUPERVECTORS, STORED IN F.
        if (ilast /= 0) call mxm (b, minear, bcoef, ilast, f, nvar_nvo) 
        do j = 1, nvar_nvo 
          f(:minear,j) = f(:minear,j)*scalar(:minear) 
        end do 
!        FOCK MATRIX DIAGONAL BLOCKS OVER C.I-ACTIVE M.O.
!        STORED IN FB.
        if (ilast /= 0) call mxm (fci, ninear, bcoef, ilast, fb, nvar_nvo) 
      endif 
!
!     * * * STEP 3 * * *
!     FINAL LOOP (390) ON THE GEOMETRIC VARIABLES.
!     --------------------------------------------
!
      do ivar = 1, nvar_nvo 
!
!     C.I-ACTIVE M.O DERIVATIVES INTO THE M.O BASIS,
!         RETURNED IN AB (N,NELEC+1,...,NELEC+NMOS).
!     C.I-ACTIVE EIGENVALUES DERIVATIVES,
!         RETURNED IN BCOEF(NELEC+1,...,NELEC+NMOS).
        call deri23 (f(1,ivar), fd(1,ivar), eigs, fb(ninear*(ivar-1)+1,1), ab, &
          bcoef) 
!
!     DERIVATIVES OF THE 2-ELECTRONS INTEGRALS OVER C.I-ACTIVE M.O.
!     STORED IN /XYIJKL/.
      iindex = Mod (norbs*nelec+1, minear)
      jindex = (norbs*nelec+1) / minear + 1
      if (iindex == 0) then
        iindex = minear
        jindex = jindex - 1
      end if
        call dijkl2 (ab(iindex, jindex))  
        if (debug) then 
          write (iw, '('' * * * GRADIENT COMPONENT NUMBER'',I4)') ivar 
          if (index(keywrd,'DEBU') /= 0) then 
            write (iw, &
      '('' C.I-ACTIVE M.O. DERIVATIVES IN M.O BASIS'',                   '', IN&
      & ROW.'')') 
            l = norbs*nelec + 1 
            do i = nelec + 1, nelec + nmos 
     !         write (iw, '(8F10.4)') (ab(k,1),k=l,l + norbs - 1) 
              l = l + norbs 
            end do 
          endif 
          write (iw, &
      &'('' C.I-ACTIVE FOCK EIGENVALUES '',               ''RELAXATION (eigs.V.)'')&
      &') 
          write (iw, '(8F10.4)') (bcoef(i),i=nelec + 1,nelec + nmos) 
          write (iw, &
      &'('' 2-ELECTRON INTEGRALS RELAXATION (eigs.V.)'',2/    ''    I    J    K    &
      &L       d<I(1)J(1)|K(2)L(2)> '',             ''RELAXATION ONLY'')') 
          do i = 1, nmos 
            do j = 1, i 
              do k = 1, i 
                ll = k 
                if (k == i) ll = j 
                do l = 1, ll 
                  write (iw, '(4I5,F20.10)') nelec + i, nelec + j, nelec + k, &
                    nelec + l, xy(i,j,k,l) 
                end do 
              end do 
            end do 
          end do 
        endif 
!
!     BUILD THE C.I MATRIX DERIVATIVE, STORED IN AB.
        call mecid (bcoef(1+nelec), gse, work(lab+1), work, xy) 
        call mecih (work, ab, nmos, lab, xy) 
!     RELAXATION CORRECTION TO THE C.I ENERGY DERIVATIVE.
        sum = 0.D0 
        if (gse > 1.d10) sum = -sum ! dummy use of gse
        do i = 1, nstate 
          j = (i - 1)*lab + 1 
          call supdot (work, ab, vectci(j), lab) 
          sum = sum + dot(vectci(j),work,lab) 
        end do 
        dxyzr(ivar) = dxyzr(ivar) + sum*const/nstate 
        if (.not.debug) cycle  
        write (iw, &
     &     '('' RELAXATION OF THE GRADIENT COMPONENT'',F10.4, '' KCAL/MOLE'')') &
     &     dot(vectci,work,lab)*const 
!
!     THE END .
      end do 
      if (debug) write (iw, &
      &'('' ELAPSED TIME IN C.I-ENERGY RELAXATION'',F15.3,                   '' &
      &SECOND'')') second(1) - time2 
      return  
      end subroutine deri2 
