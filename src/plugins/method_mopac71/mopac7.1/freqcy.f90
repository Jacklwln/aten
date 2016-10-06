      subroutine freqcy(fmatrx, freq, cnorml, redmas, travel, eorc, deldip, ff&
        , oldf) 
!-----------------------------------------------
!   M o d u l e s 
!-----------------------------------------------
      USE vast_kind_param, ONLY:  double 
      USE molkst_C, only : numat, keywrd
      USE permanent_arrays, only : atmass 
      USE funcon_C, only : fpc_10, fpc_8, fpc_6
      USE chanel_C, only : iw
!...Translated by Pacific-Sierra Research 77to90  4.4G  07:50:24  03/16/06  
!...Switches: -rl INDDO=2 INDIF=2 
!-----------------------------------------------
!   I n t e r f a c e   B l o c k s
!-----------------------------------------------
      use symt_I 
      use vecprt_I 
      use reada_I 
      use brlzon_I 
      use frame_I 
      use rsp_I 
      use symtrz_I 
      implicit none
!-----------------------------------------------
!   D u m m y   A r g u m e n t s
!-----------------------------------------------
      real(double)  :: ff(*) 
      logical , intent(in) :: eorc 
      real(double)  :: fmatrx((3*numat*(3*numat+1))/2) 
      real(double)  :: freq(3*numat) 
      real(double)  :: cnorml(9*numat*numat) 
      real(double) , intent(out) :: redmas(3*numat) 
      real(double) , intent(out) :: travel(3*numat) 
      real(double)  :: deldip(3,3*numat) 
      real(double) , intent(out) :: oldf((3*numat*(3*numat+1))/2) 
!-----------------------------------------------
!   L o c a l   V a r i a b l e s
!-----------------------------------------------
      integer :: n3, loop, i, j, ij, iu, il, im1, ju, jl, ii, jj, l, linear&
        , mono3, jii, k 
      real(double) :: step
      real(double), dimension(99) :: wtmass 
      real(double) :: fact, c2pi, sumerr, sum, err, weight, const, summ, &
        sum1 
!-----------------------------------------------
!********************************************************************
!
!  FREQCY CALCULATES THE FORCE CONSTANTS AND VIBRATIONAL FREQUENCIES
!       FOR A MOLECULE.  IT USES THE ISOTOPIC MASSES TO WEIGHT THE
!       FORCE MATRIX
!
! ON INPUT   FMATRX   =  FORCE MATRIX, OF SIZE NUMAT*3*(NUMAT*3+1)/2.
!
!********************************************************************
      fact = fpc_10 
!
!    CONVERSION FACTOR FOR SPEED OF LIGHT AND 2 PI.
!
      c2pi = 1.D0/(fpc_8*3.14159265358979D0*2.D0) 
! NOW TO CALCULATE THE VIBRATIONAL FREQUENCIES
!
!   FIND CONVERSION CONSTANTS FOR MASS WEIGHTED SYSTEM
      n3 = numat*3 
      if (index(keywrd,' NOSYM') == 0) then 
!
!     NEW FEATURE:  The diagonal terms of the Force Matrix should
!     be equal to minus the sum of the off-diagonal terms.
!
        do loop = 1, 20 
          sumerr = 0.D0 
          do i = 1, n3 
            sum = 0.D0 
            err = 0.D0 
            do j = 1, i - 1 
              sum = sum + fmatrx((i*(i-1))/2+j) 
            end do 
            do j = i + 1, n3 
              sum = sum + fmatrx((j*(j-1))/2+i) 
            end do 
            err = err + fmatrx((i*(i+1))/2) + sum 
            sumerr = sumerr + abs(err) 
            fmatrx((i*(i+1))/2) = (-sum) - err*0.5D0 
          end do 
!#      WRITE(IW,*)' LOOP:',LOOP
          call symt (fmatrx, deldip, ff) 
!#      WRITE(IW,*)LOOP,SUMERR
          if (sumerr >= 1.D-6) cycle  
          exit  
        end do 
      endif 
      if (index(keywrd,' FREQCY') /= 0) then 
        write (iw, '(A)') ' SYMMETRIZED HESSIAN MATRIX' 
!#         I=-N3
!#         CALL VECPRT(FMATRX,I)
!
!   THE FORCE MATRIX IS PRINTED AS AN ATOM-ATOM MATRIX RATHER THAN
!   AS A 3N*3N MATRIX, AS THE 3N MATRIX IS VERY CONFUSING!
!
        ij = 0 
        iu = 0 
        do i = 1, numat 
          il = iu + 1 
          iu = il + 2 
          im1 = i - 1 
          ju = 0 
          do j = 1, im1 
            jl = ju + 1 
            ju = jl + 2 
            sum = 0.D0 
            do ii = il, iu 
              do jj = jl, ju 
                sum = sum + fmatrx((ii*(ii-1))/2+jj)**2 
              end do 
            end do 
            ij = ij + 1 
            cnorml(ij) = sqrt(sum) 
          end do 
          ij = ij + 1 
          cnorml(ij) = sqrt(fmatrx(((il+0)*(il+1))/2)**2+fmatrx(((il+1)*(il+2))&
            /2)**2+fmatrx(((il+2)*(il+3))/2)**2+2.D0*(fmatrx(((il+1)*(il+2))/2-&
            1)**2+fmatrx(((il+2)*(il+3))/2-2)**2+fmatrx(((il+2)*(il+3))/2-1)**2&
            )) 
        end do 
        i = -numat 
        call vecprt (cnorml, i) 
      endif 
      l = 0 
      do i = 1, numat 
        weight = 1.D0/sqrt(atmass(i)) 
        wtmass(l+1) = weight 
        wtmass(l+2) = weight 
        wtmass(l+3) = weight 
        l = l + 3 
        wtmass(l) = weight 
      end do 
!    CONVERT TO MASS WEIGHTED FMATRX
      linear = 0 
      do i = 1, n3 
        if (i > 0) then 
          oldf(linear+1:i+linear) = fmatrx(linear+1:i+linear)*1.D5 
          fmatrx(linear+1:i+linear) = fmatrx(linear+1:i+linear)*wtmass(i)*&
            wtmass(:i) 
          linear = i + linear 
        endif 
      end do 
!
!    1.D5 IS TO CONVERT FROM MILLIDYNES/ANGSTROM TO DYNES/CM.
!
!    DIAGONALIZE
      i = index(keywrd,' K=') 
      if (i /= 0) then 
!
!  GO INTO BRILLOUIN ZONE MODE
!
        step = reada(keywrd,i) 
        mono3 = nint(reada(keywrd(i:),index(keywrd(i:),','))*3) 
        call brlzon (fmatrx, n3, mono3, step, 1)
        return  
      endif 
      call frame (fmatrx, numat, 1) 
      call rsp (fmatrx, n3, n3, freq, cnorml) 
      if (eorc) call symtrz (cnorml, freq, 2, .TRUE.) 
      do i = 1, n3 
        j = int((freq(i)+50.D0)*0.01D0) 
        freq(i) = freq(i) - dble(j*100) 
      end do 
      freq(:n3) = freq(:n3)*1.D5 
!
!     CONST = SQRT(2*h*c*1.D11) = conversion from cm**(-1) to
!             dyne-Angstroms
!
      const = sqrt(2.D0*fpc_6*fpc_8*1.D11) 
!
!    CALCULATE REDUCED MASSES, STORE IN REDMAS
!
      do i = 1, n3 
        ii = (i - 1)*n3 
        summ = 0.D0 
        do j = 1, numat 
          summ = summ + (cnorml(ii+j*3-2)**2+cnorml(ii+j*3-1)**2+cnorml(ii+j*3)&
            **2)**2*atmass(j) 
        end do 
        sum = 0.D0 
        do j = 1, n3 
          jii = j + ii 
          jj = (j*(j - 1))/2 
          do k = 1, j 
            sum = sum + cnorml(jii)*oldf(jj+k)*cnorml(k+ii) 
          end do 
          do k = j + 1, n3 
            sum = sum + cnorml(jii)*oldf((k*(k-1))/2+j)*cnorml(k+ii) 
          end do 
        end do 
        sum = sum*0.5d0  ! WARNING: Check the absolute values in oldf
        sum1 = sum*2.D0 
        if (abs(freq(i)) > abs(sum)*1.D-20) then 
          sum = 1.D0*sum/freq(i) 
        else 
          sum = 0.D0 
        endif 
        freq(i) = sign(sqrt(fact*abs(freq(i)))*c2pi,freq(i)) 
        if (abs(freq(i)) < abs(sum1)*1.D+20) then 
          sum1 = sqrt(abs(freq(i)/(sum1*1.D-5))) 
        else 
          sum1 = 0.D0 
        endif 
        if (sum<0.D0 .or. sum>100) sum = 0.D0 
        travel(i) = sum1*const 
        if (travel(i) > 1.D0) travel(i) = 0.D0 
        redmas(i) = summ 
      end do 
      if (eorc) then 
!
!    CONVERT NORMAL VECTORS TO CARTESIAN COORDINATES
!    (DELETED) AND NORMALIZE SO THAT THE TOTAL MOVEMENT IS 1.0 ANGSTROM.
!
        ij = 0 
        do i = 1, n3 
          sum = 0.D0 
          j = 0 
          do jj = 1, numat 
            sum1 = 0.D0 
            cnorml(ij+1) = cnorml(ij+1)*wtmass(j+1) 
            sum1 = sum1 + cnorml(ij+1)**2 
!
            cnorml(ij+2) = cnorml(ij+2)*wtmass(j+2) 
            sum1 = sum1 + cnorml(ij+2)**2 
!
            cnorml(ij+3) = cnorml(ij+3)*wtmass(j+3) 
            sum1 = sum1 + cnorml(ij+3)**2 
!
            j = j + 3 
            ij = ij + 3 
            sum = sum + sqrt(sum1) 
          end do 
          sum = 1.D0/sum 
          ij = ij - n3 
          cnorml(ij+1:n3+ij) = cnorml(ij+1:n3+ij)*sum 
          ij = n3 + ij 
        end do 
!
!          RETURN HESSIAN IN MILLIDYNES/ANGSTROM IN FMATRX
!
        fmatrx(:linear) = oldf(:linear)*1.D-5 
      else 
!
!  RETURN HESSIAN AS MASS-WEIGHTED FMATRIX
        linear = 0 
!
        do i = 1, n3 
          if (i > 0) then 
            fmatrx(linear+1:i+linear) = oldf(linear+1:i+linear)*1.D-5*wtmass(i)&
              *wtmass(:i) 
            linear = i + linear 
          endif 
        end do 
      endif 
      return  
      end subroutine freqcy 
