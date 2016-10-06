      subroutine prtdrc(deltt, xparam, ref, ekin, gtot, etot, velo0, mcoprt, ncoprt, parmax) 
!-----------------------------------------------
!   M o d u l e s 
!-----------------------------------------------
      USE vast_kind_param, ONLY:  double  
      USE molkst_C, only : numat, keywrd, numcal, escf, nvar
      use permanent_arrays, only : nat, na, nb, nc, p
      USE parameters_C, only : tore
      use chanel_C, only : iw, ires
!...Translated by Pacific-Sierra Research 77to90  4.4G  11:04:59  03/09/06  
!...Switches: -rl INDDO=2 INDIF=2 
!-----------------------------------------------
!   I n t e r f a c e   B l o c k s
!-----------------------------------------------
      use reada_I 
      use chrge_I 
      use xyzint_I 
      use quadr_I 
      use drcout_I 
      use dot_I 
      implicit none
!-----------------------------------------------
!   G l o b a l   P a r a m e t e r s
!-----------------------------------------------
!-----------------------------------------------
!   D u m m y   A r g u m e n t s
!----------------------------------------------- 
      real(double) , intent(in) :: deltt 
      real(double) , intent(in) :: ekin 
      real(double) , intent(inout) :: gtot 
      real(double)  :: etot 
      real(double), dimension(3*numat) :: xparam, ref, velo0
      integer, dimension (3, numat) :: mcoprt  
      integer, intent(in) ::  ncoprt
      logical, intent(in) :: parmax
!-----------------------------------------------
!   L o c a l   P a r a m e t e r s
!-----------------------------------------------
!-----------------------------------------------
!   L o c a l   V a r i a b l e s
!-----------------------------------------------
      integer ::  iloop, icalcn, ione, jloop, i, l, j, nfract, ii, n, &
        k 
      real(double), dimension(3) :: escf3, ekin3
      real(double), dimension(numat) :: charge 
      real(double), dimension(3) :: xold3 
      real(double), dimension(3*numat) :: geo 
      real(double), dimension(:), allocatable :: vref, vref0 
      real(double), dimension(100) :: tsteps 
      real(double), dimension(3) :: etot3, xtot3 
      real(double) :: gtot0, gtot1, escf0, escf1, ekin0, ekin1, etot0, etot1, &
        xold0, xold1, xold2, refscf, totime, told2, told1, refx, tlast, &
        stept, steph, stepx, tref, xtot0, xtot1, xtot2, etot2, escf2, ekin2, &
        sum, deltat, t1, t2, sum1, dh, cc, bb, aa, c1, time, fract
      logical :: goturn, ldrc 
      real(double), dimension(:,:), allocatable :: allxyz, allvel, xyz3, vel3, allgeo, geo3  
      real(double), dimension(:), allocatable :: parref 
      character , dimension(3) :: cotype*2 
      character :: text1*3, text2*2 

      save vref, vref0, gtot0, gtot1, escf0, escf1, ekin0, ekin1, etot0, etot1&
        , xold0, xold1, xold2, refscf, cotype, iloop, totime, told2, told1, &
        icalcn, refx, tlast, goturn, ione, ldrc, stept, steph, stepx, &
        tref, jloop, xtot0, xtot1, xtot2, allxyz, allvel, parref, &
        xyz3, vel3, allgeo, geo3 
!-----------------------------------------------
!********************************************************************
!
!    PRTDRC PREPARES TO PRINT THE GEOMETRY ETC. FOR POINTS IN A DRC
!    OR IRC
!    CALCULATION.
!    ON INPUT  ESCF   = HEAT OF FORMATION FOR THE CURRENT POINT
!              DELTT  = CHANGE IN TIME, PREVIOUS TO CURRENT POINT
!              XPARAM = CURRENT CARTESIAN GEOMETRY
!              EKIN   = CURRENT KINETIC ENERGY
!              GTOT   = TOTAL GRADIENT NORM IN IRC CALC'N.
!              VELO0  = CURRENT VELOCITY
!              NVAR   = NUMBER OF VARIABLES = 3 * NUMBER OF ATOMS.
!
!*******************************************************************
      data icalcn/ 0/  
      data refscf/ 0.D0/  
      data cotype/ 'BL', 'BA', 'DI'/  
      if (icalcn /= numcal) then 
        if (allocated(vref)) deallocate(vref)
        if (allocated(vref0)) deallocate(vref0)
        if (allocated(allxyz)) deallocate(allxyz)
        if (allocated(allvel)) deallocate(allvel)
        if (allocated(xyz3)) deallocate(xyz3)
        if (allocated(vel3)) deallocate(vel3)
        if (allocated(allgeo)) deallocate(allgeo)
        if (allocated(geo3)) deallocate(geo3)
        if (allocated(parref)) deallocate(parref)
        i = 3*numat
        allocate(vref(i), vref0(i), allxyz(3,i), allvel(3,i), xyz3(3,i), vel3(3,i), &
        allgeo(3,i), geo3(3,i), parref(i) )
        icalcn = numcal 
        totime = 0.D0 
        etot0 = 0.0D0 
        etot1 = 0.0D0 
        etot2 = 0.0D0 
        escf0 = 0.0D0 
        escf1 = 0.0D0 
        escf2 = 0.0D0 
        ekin0 = 0.0D0 
        ekin1 = 0.0D0 
        ekin2 = 0.0D0 
        gtot = 0.D0 
        gtot0 = 0.0D0 
        gtot1 = 0.0D0 
        refx = 0.D0 
        fract = 0.D0 
        told2 = 0.D0 
        xold0 = 0.D0 
        xold1 = 0.D0 
        xold2 = 0.D0 
        xtot0 = 0.D0 
        xtot1 = 0.D0 
        xtot2 = 0.D0 
        parref(:nvar) = xparam(:nvar) 
        etot = escf + ekin 
        tlast = 0.D0 
        goturn = .FALSE. 
        sum = 0.D0 
        do i = 1, nvar 
          sum = sum + velo0(i)**2 
          vref0(i) = velo0(i) 
          vref(i) = velo0(i) 
        end do 
        ione = 1 
        ldrc = sum > 1.D0 
        iloop = 1 
        told1 = 0.0D0 
!
!       DETERMINE TYPE OF PRINT: TIME, ENERGY OR GEOMETRY PRIORITY
!       OR PRINT ALL POINTS
!
        stept = 0.D0 
        steph = 0.D0 
        stepx = 0.D0 
        if (index(keywrd,' T-PRIO') /= 0) then 
          if (index(keywrd,' T-PRIORITY=') /= 0) then 
            stept = reada(keywrd,index(keywrd,'T-PRIO') + 5) 
          else 
            stept = 0.1D0 
          endif 
          tref = -1.D-6 
          write (iw, &
      '(/,'' TIME PRIORITY, INTERVAL ='',F4.1,           '' FEMTOSECONDS'',/)')&
             stept 
        else if (index(keywrd,' H-PRIO') /= 0) then 
          if (index(keywrd,' H-PRIORITY=') /= 0) then 
            steph = reada(keywrd,index(keywrd,'H-PRIO') + 5) 
          else 
            steph = 0.1D0 
          endif 
          write (iw, &
      '(/,'' KINETIC ENERGY PRIORITY, STEP ='',F5.2,     '' KCAL/MOLE'',/)') &
            steph 
        else if (index(keywrd,' X-PRIO') /= 0) then 
          if (index(keywrd,' X-PRIORITY=') /= 0) then 
            stepx = reada(keywrd,index(keywrd,'X-PRIO') + 5) 
          else 
            stepx = 0.05D0 
          endif 
          write (iw, &
      '(/,'' GEOMETRY PRIORITY, STEP ='',F5.2,           '' ANGSTROMS'',/)') &
            stepx 
        endif 
        if (index(keywrd,' RESTART')/=0 .and. index(keywrd,'IRC=')==0) then 
            read (ires) (parref(i),i=1,nvar) 
            read (ires) (ref(i),i=1,nvar) 
            read (ires) (vref0(i),i=1,nvar) 
            read (ires) (vref(i),i=1,nvar) 
            read (ires) (allgeo(3,i),i=1,nvar) 
            read (ires) (allgeo(2,i),i=1,nvar) 
            read (ires) (allgeo(1,i),i=1,nvar) 
            read (ires) (allvel(3,i),i=1,nvar) 
            read (ires) (allvel(2,i),i=1,nvar) 
            read (ires) (allvel(1,i),i=1,nvar) 
            read (ires) (allxyz(3,i),i=1,nvar) 
            read (ires) (allxyz(2,i),i=1,nvar) 
            read (ires) (allxyz(1,i),i=1,nvar) 
            read (ires) iloop, ldrc, ione, etot1, etot0, escf1, escf0, ekin1, &
              ekin0, told2, told1, gtot1, gtot0, xold2, xold1, xold0, totime, &
              jloop, etot, refx, xtot1, xtot0  
        endif 
      endif 
      if (escf < (-1.D8)) then 
          write (ires) (parref(i),i=1,nvar) 
          write (ires) (ref(i),i=1,nvar) 
          write (ires) (vref0(i),i=1,nvar) 
          write (ires) (vref(i),i=1,nvar) 
          write (ires) (allgeo(3,i),i=1,nvar) 
          write (ires) (allgeo(2,i),i=1,nvar) 
          write (ires) (allgeo(1,i),i=1,nvar) 
          write (ires) (allvel(3,i),i=1,nvar) 
          write (ires) (allvel(2,i),i=1,nvar) 
          write (ires) (allvel(1,i),i=1,nvar) 
          write (ires) (allxyz(3,i),i=1,nvar) 
          write (ires) (allxyz(2,i),i=1,nvar) 
          write (ires) (allxyz(1,i),i=1,nvar) 
          write (ires) iloop, ldrc, ione, etot1, etot0, escf1, escf0, ekin1, &
            ekin0, told2, told1, gtot1, gtot0, xold2, xold1, xold0, totime, &
            jloop, etot, refx, xtot1, xtot0 
        close(ires, status='KEEP') 
        return  
      endif 
      call chrge (p, charge) 
      charge(:numat) = tore(nat(:numat)) - charge(:numat) 
      deltat = deltt*1.D15 
      na(2) = -1 
      call xyzint (xparam, numat, na, nb, nc, 57.29577951308232D0, geo) 
      na(1) = 99 
      if (iloop == 1) then 
        etot1 = etot0 
        etot0 = etot 
        escf1 = escf 
        escf0 = escf 
        ekin1 = ekin 
        ekin0 = ekin 
        do j = 1, 3 
!$DOIT VBEST
          allgeo(j,:nvar) = geo(:nvar) 
          allxyz(j,:nvar) = xparam(:nvar) 
          allvel(j,:nvar) = velo0(:nvar) 
        end do 
      else 
        allgeo(3,:nvar) = allgeo(2,:nvar) 
        allgeo(2,:nvar) = allgeo(1,:nvar) 
        allgeo(1,:nvar) = geo(:nvar) 
        allxyz(3,:nvar) = allxyz(2,:nvar) 
        allxyz(2,:nvar) = allxyz(1,:nvar) 
        allxyz(1,:nvar) = xparam(:nvar) 
        allvel(3,:nvar) = allvel(2,:nvar) 
        allvel(2,:nvar) = allvel(1,:nvar) 
        allvel(1,:nvar) = velo0(:nvar) 
      endif 
!
!  FORM QUADRATIC EXPRESSION FOR POSITION AND VELOCITY W.R.T. TIME.
!
      t1 = max(told2,0.02D0) 
      t2 = max(told1,0.02D0) + t1 
      do i = 1, nvar 
        call quadr (allgeo(3,i), allgeo(2,i), allgeo(1,i), t1, t2, geo3(1,i), &
          geo3(2,i), geo3(3,i)) 
!
!***************************************************
!                                                  *
!    QUADR CALCULATES THE A, B AND C IN THE EQUNS. *
!                                                  *
!     A                   =   F0                   *
!     A + B.X0 + C.X0**2  =   F1                   *
!     A + B.X2 + C.X2**2  =   F2                   *
! GIVEN THE ARGUMENT LIST (F0,F1,F2, X1,X2, A,B,C) *
!                                                  *
!***************************************************
        call quadr (allxyz(3,i), allxyz(2,i), allxyz(1,i), t1, t2, xyz3(1,i), &
          xyz3(2,i), xyz3(3,i)) 
        call quadr (allvel(3,i), allvel(2,i), allvel(1,i), t1, t2, vel3(1,i), &
          vel3(2,i), vel3(3,i)) 
      end do 
      etot2 = etot1 
      etot1 = etot0 
      etot0 = etot 
      call quadr (etot2, etot1, etot0, t1, t2, etot3(1), etot3(2), etot3(3)) 
      ekin2 = ekin1 
      ekin1 = ekin0 
      ekin0 = ekin 
      call quadr (ekin2, ekin1, ekin0, t1, t2, ekin3(1), ekin3(2), ekin3(3)) 
      escf2 = escf1 
      escf1 = escf0 
      escf0 = escf 
      call quadr (escf2, escf1, escf0, t1, t2, escf3(1), escf3(2), escf3(3)) 
      gtot1 = gtot0 
      gtot0 = gtot 
      xtot2 = xtot1 
      xtot1 = xtot0 
      xold2 = xold2 + xold1 
      xold1 = xold0 
!
!   CALCULATE CHANGE IN GEOMETRY
!
      xold0 = 0.D0 
      l = 0 
      xtot0 = 0.D0 
      sum1 = 0.D0 
      do i = 1, numat 
        sum = 0.D0 
        sum1 = 0.D0 
!$DOIT ASIS
        do j = 1, 3 
          l = l + 1 
          sum1 = sum1 + (allxyz(1,l)-ref(l))**2 
          sum = sum + (allxyz(2,l)-allxyz(1,l))**2 
        end do 
        xold0 = xold0 + sqrt(sum) 
        xtot0 = xtot0 + sqrt(sum1) 
      end do 
      call quadr (xtot2, xtot1, xtot0, t1, t2, xtot3(1), xtot3(2), xtot3(3)) 
      call quadr (xold2, xold2 + xold1, xold2 + xold1 + xold0, t1, t2, xold3(1)&
        , xold3(2), xold3(3)) 
!**********************************************************************
!   GO THROUGH THE CRITERIA FOR DECIDING WHETHER OR NOT TO PRINT THIS *
!   POINT.  IF YES, THEN ALSO CALCULATE THE EXACT POINT AS A FRACTION *
!   BETWEEN THE LAST POINT AND THE CURRENT POINT                      *
!**********************************************************************
!   NFRACT IS THE NUMBER OF POINTS TO BE PRINTED IN THE CURRENT DOMAIN
!**********************************************************************
      if (iloop >= 3) then 
        fract = -10.D0 
        nfract = 1 
        if (Abs(steph) > 1.d-20) then 
!
!   CRITERION FOR PRINTING RESULTS  IS A CHANGE IN HEAT OF FORMATION =
!   -CHANGE IN KINETIC ENERGY
!
          if (refscf == 0.D0) then 
            i = int(escf2/steph) 
            refscf = i*steph 
          endif 
          dh = abs(escf1 - refscf) 
          if (dh > steph) then 
            steph = sign(steph,escf1 - refscf) 
            nfract = int(abs(dh/steph)) 
            cc = escf3(1) 
            bb = escf3(2) 
            aa = escf3(3) 
!***********************************************
! PROGRAMMERS! - BE VERY CAREFUL IF YOU CHANGE *
! THIS FOLLOWING SECTION.  THERE IS NUMERICAL  *
! INSTABILITY IF ABS(BB/AA) IS VERY LARGE. NEAR*
! INFLECTION POINTS AA CHANGES SIGN.       JJPS*
!***********************************************
            if (abs(bb/aa) > 30) then 
!
!   USE LINEAR INTERPOLATION
!
              do i = 1, nfract 
                tsteps(i) = -(cc - (refscf + i*steph))/bb 
              end do 
            else 
!
!  USE QUADRATIC INTERPOLATION
!
              do i = 1, nfract 
                c1 = cc - (refscf + i*steph) 
                tsteps(i) = ((-bb) + sign(sqrt(bb*bb - 4.D0*(aa*c1)),bb))/(2.D0&
                  *aa) 
              end do 
            endif 
            fract = -.1D0 
            refscf = refscf + nfract*steph 
          endif 
        else if (stept /= 0.D0) then 
!
!   CRITERION FOR PRINTING RESULTS IS A CHANGE IN TIME.
!
          if (abs(totime + told2 - tref) > stept) then 
            i = int(totime/stept) 
            fract = i*stept - totime 
            i = int((told2 + totime)/stept) 
            j = int(totime/stept) 
            nfract = i - j + ione 
            ione = 0 
            do i = 1, nfract 
              tsteps(i) = fract + i*stept 
            end do 
            tref = tref + nfract*stept 
          endif 
        else if (stepx /= 0.D0) then 
!
!   CRITERION FOR PRINTING RESULTS IS A CHANGE IN GEOMETRY.
!
          if (xold2 + xold1 - refx > stepx) then 
            nfract = int((xold2 + xold1 - refx)/stepx) 
            cc = xold3(1) 
            bb = xold3(2) 
            aa = xold3(3) 
            if (abs(bb/aa) > 30) then 
!
!   USE LINEAR INTERPOLATION
!
              do i = 1, nfract 
                tsteps(i) = -(cc - (refx + i*stepx))/bb 
              end do 
            else 
!
!  USE QUADRATIC INTERPOLATION
!
              do i = 1, nfract 
                c1 = cc - (refx + i*stepx) 
                tsteps(i) = ((-bb) + sign(sqrt(bb*bb - 4.D0*(aa*c1)),bb))/(2.D0&
                  *aa) 
              end do 
            endif 
            refx = refx + nfract*stepx 
            fract = -.1D0 
          endif 
        else 
!
!   PRINT EVERY POINT.
!
          fract = 0.0D0 
        endif 
        if (fract >= (-9.D0)) then 
!
!  LOOP OVER ALL POINTS IN CURRENT DOMAIN
!
          if (fract==0.D0 .and. nfract==1) then 
            text1 = ' ' 
            text2 = ' ' 
            ii = 0 
            call drcout (xyz3, geo3, vel3, nvar, totime, escf3, ekin3, etot3, &
              xtot3, iloop, charge, fract, text1, text2, ii, jloop) 
            n = 0 
            do i = 1, ncoprt 
              k = mcoprt(1,i) 
              j = mcoprt(2,i) 
              l = k*3 - 3 + j 
              if (abs(geo3(3,l)) > 1.D-20) fract = -geo3(2,l)/(geo3(3,l)*2.D0) 
              if (fract<=0.D0 .or. fract>=told2) cycle  
              if (geo3(3,l) > 0.D0) text1 = 'MIN' 
              if (geo3(3,l) < 0.D0) text1 = 'MAX' 
              text2 = cotype(j) 
              if (n == 0) then 
                n = n + 1 
                write (iw, '(/,20(''****''))') 
              endif 
              time = totime + fract 
              call drcout (xyz3, geo3, vel3, nvar, time, escf3, ekin3, etot3, &
                xtot3, iloop, charge, fract, text1, text2, k, jloop) 
            end do 
            if (n /= 0) write (iw, '(/,20(''****''))') 
            if (abs(escf3(3)) > 1.D-20) fract = -escf3(2)/(escf3(3)*2.D0) 
            if (.not. goturn .and. fract > 0.D0 .and. fract < told2*1.04D0 .and. parmax) then 
              goturn = .TRUE. 
              time = fract + totime 
              if (escf3(3) > 0.D0) then 
                text1 = 'MIN' 
                if (ldrc) then 
                  sum = dot(velo0,vref,nvar)**2/(dot(velo0,velo0,nvar)*dot(vref&
                    ,vref,nvar) + 1.D-10) 
                  sum1 = dot(velo0,vref0,nvar)**2/(dot(velo0,velo0,nvar)*dot(&
                    vref0,vref0,nvar) + 1.D-10) 
                  if (sum1>0.1D0 .and. abs(sum1-1.D0)>1.D-6) write (iw, &
                    '(/,A,F8.5,A,F8.5,A,G12.3,A)') &
                    ' COEF. OF V(0)            =', sum1, '   LAST V(0)', sum, &
                    '   HALF-LIFE =', (-0.6931472D0*time/log(sum1)), &
                    ' FEMTOSECS' 
                endif 
                write (iw, '(2/,A,F11.3,A)') ' HALF-CYCLE TIME =', time - tlast&
                  , ' FEMTOSECONDS' 
                tlast = time 
                vref(:nvar) = velo0(:nvar) 
              endif 
              if (escf3(3) < 0.D0) text1 = 'MAX' 
              text2 = ' ' 
              call drcout (xyz3, geo3, vel3, nvar, time, escf3, ekin3, etot3, &
                xtot3, iloop, charge, fract, text1, text2, 0, jloop) 
            else 
              goturn = .FALSE. 
            endif 
          else 
            do i = 1, nfract 
              time = totime + tsteps(i) 
              text1 = ' ' 
              text2 = ' ' 
              call drcout (xyz3, geo3, vel3, nvar, time, escf3, ekin3, etot3, &
                xtot3, iloop, charge, tsteps(i), text1, text2, 0, jloop) 
            end do 
          endif 
        endif 
      endif 
      totime = totime + told2 
      told2 = told1 
      told1 = deltat 
      iloop = iloop + 1 
      endfile (iw) 
      backspace (iw) 
      return  
      end subroutine prtdrc 
