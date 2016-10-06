      subroutine hcored() 
!-----------------------------------------------
!   M o d u l e s 
!-----------------------------------------------
      USE vast_kind_param, ONLY:  double  
      USE permanent_arrays, only : coord, nfirst, nlast, nat, h, w, nw
      use molkst_C, only : numat, n2elec, enuclr, atheat 
      USE parameters_C, only : eisol, eheat,dorbs, uss, upp, udd
      USE overlaps_C, only : cutof1, cutof2 
      USE funcon_C, only : fpc_9
      use cosmo_C, only :useps
!***********************************************************************
!DECK MOPAC
!...Translated by Pacific-Sierra Research 77to90  4.4G  12:41:19  03/10/06  
!...Switches: -rl INDDO=2 INDIF=2 
!-----------------------------------------------
!   I n t e r f a c e   B l o c k s
!-----------------------------------------------
      use h1elec_I 
      use rotatd_I 
      use elenuc_I 
      use wstore_I 
      use addhcr_I 
      use addnuc_I 
      implicit none
!-----------------------------------------------
!   L o c a l   V a r i a b l e s
!-----------------------------------------------
      integer :: i, ni, ia, ll, ib, ic, j, nj, ja, jb, i2, i1, ii, ip, &
        jp
      real(double), dimension(9,9) :: di 
      real(double) :: eat, enuc 
!-----------------------------------------------
! COSMO change
! end of COSMO change
! *** INITIALIZE SOME VARIABLES.
      enuclr = 0.d0 
      cutof2 = 1.D10 
      cutof1 = 1.D10 
      h = 0.d0 
      w = 0.d0 
      eat = 0.d0 
      atheat = sum(eheat(nat(:numat))) 
      eat = eat + sum(eisol(nat(:numat))) 
      atheat = atheat - eat*fpc_9 
!
! *** DIAGONAL ONE-CENTER TERMS.
      do i = 1, numat 
        ni = nat(i) 
        ia = nfirst(i) 
        ll = (ia*(ia + 1))/2 
        h(ll) = uss(ni) 
        if (ni < 3) cycle  
        ib = nlast(i) 
        ic = ia + 1 
        do j = ic, ib 
          ll = (j*(j + 1))/2 
          h(ll) = upp(ni) 
        end do 
        if (.not.dorbs(ni)) cycle  
        ic = ia + 4 
        do j = ic, ib 
          ll = j*(j + 1)/2 
          h(ll) = udd(ni) 
        end do 
      end do 
!
! *** LOOP OVER ATOM PAIRS FOR OFF-DIAGONAL TWO-CENTER TERMS.
!     ATOMS I AND J ARE IDENTIFIED AT THE BEGINNING OF THE LOOP.
      do i = 2, numat 
        ni = nat(i) 
        ia = nfirst(i) 
        ib = nlast(i) 
        do j = 1, i - 1 
          nj = nat(j) 
          ja = nfirst(j) 
          jb = nlast(j) 
!
!    one-electron integrals
!
          call h1elec (ni, nj, coord(1,i), coord(1,j), di) 
          i2 = 0 
          do i1 = ia, ib 
            ii = i1*(i1 - 1)/2 + ja - 1 
            i2 = i2 + 1 
            h(ii+1:jb-ja+1+ii) = di(i2,:jb-ja+1) 
          end do 
!
!     TWO-ELECTRON one and two center terms.
!
          ip = nw(i) 
          jp = nw(j) 
          call rotatd (ip, jp, ia, ib, ja, jb, ni, nj, coord(1,i), coord(1,j), &
            w, n2elec, enuc) 
!
!   Electron-nuclear attraction terms
!
          call elenuc (ia, ib, ja, jb, h) 
!
!   Nuclear-nuclear repulsions
!
          enuclr = enuclr + enuc 
        end do 
      end do 
! *** STORE MNDO INTEGRALS IN SQUARE FORM.
      call wstore (w) 
! COSMO change
! A. KLAMT 16.7.91
      if (useps) then 
! The following routine adds the dielectric correction for the electron-
! interaction to the diagonal elements of H
        call addhcr ()
! In the following routine the dielectric correction to the core-core-
! interaction is added to ENUCLR
        call addnuc ()
      endif 
! end of COSMO change
      return  
      end subroutine hcored 


      subroutine inid 
!-----------------------------------------------
!   M o d u l e s 
!-----------------------------------------------
      USE molkst_C, only : method_dorbs
      USE parameters_C, only : am, ad, aq, dd, qq, dorbs, po, ddp, pocord
!     *
!     DEFINE SEVERAL PARAMETERS FOR D-ORBITAL CALCULATIONS.
!     *
!...Translated by Pacific-Sierra Research 77to90  4.4G  12:41:19  03/10/06  
!...Switches: -rl INDDO=2 INDIF=2 
!-----------------------------------------------
!   I n t e r f a c e   B l o c k s
!-----------------------------------------------
      use fbx_I 
      use fordd_I 
      use mlig_I 
      use aijm_I 
      use inighd_I 
      use ddpo_I 
      implicit none
!-----------------------------------------------
!   L o c a l   V a r i a b l e s
!-----------------------------------------------
      integer :: ni, i 
!-----------------------------------------------
      if (method_dorbs) then 
        call fbx 
        call fordd 
        call mlig 
      endif 
      do ni = 1, 107 
        if (.not.dorbs(ni)) cycle  
        call aijm (ni) 
        call inighd (ni) 
        call ddpo (ni) 
      end do 
      do i = 1, 98 
        if (.not.dorbs(i)) then 
          if (am(i) < 1.D-4) am(i) = 1.D0 
          po(1,i) = 0.5D0/am(i) 
          if (ad(i) > 1.D-5) po(2,i) = 0.5D0/ad(i) 
          if (aq(i) > 1.D-5) po(3,i) = 0.5D0/aq(i) 
          po(7,i) = po(1,i) 
          po(9,i) = po(1,i) 
          ddp(2,i) = dd(i) 
          ddp(3,i) = qq(i)*sqrt(2.D0) 
        endif 
        if (.not.(method_dorbs .and. pocord(i)>1.D-5)) cycle  
        po(9,i) = pocord(i) 
      end do 
      po(2,1) = 0.D0 
      po(3,1) = 0.D0 
      return  
      end subroutine inid 


      subroutine inighd(ni) 
!-----------------------------------------------
!   M o d u l e s 
!-----------------------------------------------
      USE vast_kind_param, ONLY:  double  
      use parameters_C, only : dorbs, f0dd, f2dd, f4dd, f0sd, g2sd, f0pd, f2pd, g1pd, &
      & g3pd
      use mndod_C, only : repd
!     *
!     ONE-CENTER TWO-ELECTRON INTEGRALS FOR SPD-BASIS.
!     *
!...Translated by Pacific-Sierra Research 77to90  4.4G  12:41:19  03/10/06  
!...Switches: -rl INDDO=2 INDIF=2 
!-----------------------------------------------
!   I n t e r f a c e   B l o c k s
!-----------------------------------------------
      use scprm_I 
      use eiscor_I 
      implicit none
!-----------------------------------------------
!   D u m m y   A r g u m e n t s
!-----------------------------------------------
      integer  :: ni 
!-----------------------------------------------
!   L o c a l   V a r i a b l e s
!-----------------------------------------------
      real(double) :: s3, s5, s15, r066, r266, r466, r016, r244, r036, r236, &
        r155, r355, r125, r234, r246 
!-----------------------------------------------
      data s3/ 1.7320508D0/  
      data s5/ 2.23606797D0/  
      data s15/ 3.87298334D0/  
!
      if (.not.dorbs(ni)) return  
!
!     SLATER-CONDON PARAMETERS (RLIJ).
!     FIRST  DIGIT (L)  L QUANTUM NUMBER OF SLATER-CONDON PARAMETER.
!     SECOND DIGIT (I)  SS 1, SP 2, PP 3, SD 4, PD 5, DD 6 - ELECTRON 1.
!     SECOND DIGIT (J)  SS 1, SP 2, PP 3, SD 4, PD 5, DD 6 - ELECTRON 2.
      call scprm (ni, r066, r266, r466, r016, r244, r036, r236, r155, r355, &
        r125, r234, r246) 
      if (f0sd(ni) > 0.001D0) r016 = f0sd(ni) 
      if (g2sd(ni) > 0.001D0) r244 = g2sd(ni) 
      call eiscor (r016, r066, r244, r266, r466, ni) 
      repd(1,ni) = r016 
      repd(2,ni) = 2.d0/(3.D0*s5)*r125 
      repd(3,ni) = 1.d0/s15*r125 
      repd(4,ni) = 2.d0/(5.D0*s5)*r234 
      repd(5,ni) = r036 + 4.D0/35.D0*r236 
      repd(6,ni) = r036 + 2.D0/35.D0*r236 
      repd(7,ni) = r036 - 4.D0/35.D0*r236 
      repd(8,ni) = -1.d0/(3.D0*s5)*r125 
      repd(9,ni) = sqrt(3.D0/125.D0)*r234 
      repd(10,ni) = s3/35.D0*r236 
      repd(11,ni) = 3.D0/35.D0*r236 
      repd(12,ni) = -1.d0/(5.D0*s5)*r234 
      repd(13,ni) = r036 - 2.D0/35.D0*r236 
      repd(14,ni) = -2.D0*s3/35.D0*r236 
      repd(15,ni) = -repd(3,ni) 
      repd(16,ni) = -repd(11,ni) 
      repd(17,ni) = -repd(9,ni) 
      repd(18,ni) = -repd(14,ni) 
      repd(19,ni) = 1.d0/5.D0*r244 
      repd(20,ni) = 2.D0/(7.D0*s5)*r246 
      repd(21,ni) = repd(20,ni)/2.d0 
      repd(22,ni) = -repd(20,ni) 
      repd(23,ni) = 4.D0/15.D0*r155 + 27.D0/245.D0*r355 
      repd(24,ni) = 2.D0*s3/15.D0*r155 - 9.D0*s3/245.D0*r355 
      repd(25,ni) = 1.d0/15.D0*r155 + 18.D0/245.D0*r355 
      repd(26,ni) = (-s3/15.D0*r155) + 12.D0*s3/245.D0*r355 
      repd(27,ni) = (-s3/15.D0*r155) - 3.D0*s3/245.D0*r355 
      repd(28,ni) = -repd(27,ni) 
      repd(29,ni) = r066 + 4.D0/49.D0*r266 + 4.D0/49.D0*r466 
      repd(30,ni) = r066 + 2.D0/49.D0*r266 - 24.D0/441.D0*r466 
      repd(31,ni) = r066 - 4.D0/49.D0*r266 + 6.D0/441.D0*r466 
      repd(32,ni) = sqrt(3.D0/245.D0)*r246 
      repd(33,ni) = 1.d0/5.D0*r155 + 24.D0/245.D0*r355 
      repd(34,ni) = 1.d0/5.D0*r155 - 6.D0/245.D0*r355 
      repd(35,ni) = 3.D0/49.D0*r355 
      repd(36,ni) = 1.d0/49.D0*r266 + 30.D0/441.D0*r466 
      repd(37,ni) = s3/49.D0*r266 - 5.D0*s3/441.D0*r466 
      repd(38,ni) = r066 - 2.D0/49.D0*r266 - 4.D0/441.D0*r466 
      repd(39,ni) = (-2.D0*s3/49.D0*r266) + 10.D0*s3/441.D0*r466 
      repd(40,ni) = -repd(32,ni) 
      repd(41,ni) = -repd(34,ni) 
      repd(42,ni) = -repd(35,ni) 
      repd(43,ni) = -repd(37,ni) 
      repd(44,ni) = 3.D0/49.D0*r266 + 20.D0/441.D0*r466 
      repd(45,ni) = -repd(39,ni) 
      repd(46,ni) = 1.D0/5.D0*r155 - 3.D0/35.D0*r355 
      repd(47,ni) = -repd(46,ni) 
      repd(48,ni) = 4.D0/49.D0*r266 + 15.D0/441.D0*r466 
      repd(49,ni) = 3.D0/49.D0*r266 - 5.D0/147.D0*r466 
      repd(50,ni) = -repd(49,ni) 
      repd(51,ni) = r066 + 4.D0/49.D0*r266 - 34.D0/441.D0*r466 
      repd(52,ni) = 35.D0/441.D0*r466 
      f0dd(ni) = r066 
      f2dd(ni) = r266 
      f4dd(ni) = r466 
      f0sd(ni) = r016 
      g2sd(ni) = r244 
      f0pd(ni) = r036 
      f2pd(ni) = r236 
      g1pd(ni) = r155 
      g3pd(ni) = r355 
      return  
      end subroutine inighd 


      subroutine mlig 
!-----------------------------------------------
!   M o d u l e s 
!-----------------------------------------------
      USE mndod_C, only : nalp, iaf, ial, alpb
!     *
!...Translated by Pacific-Sierra Research 77to90  4.4G  12:41:19  03/10/06  
!...Switches: -rl INDDO=2 INDIF=2 
      implicit none
!-----------------------------------------------
!   L o c a l   V a r i a b l e s
!-----------------------------------------------
!-----------------------------------------------
!
!     BOND PARAMETERS FOR CORE-CORE REPULSION FUNCTION IN MNDO/d.
!     *
! *** CHECK FOR METHOD.
      nalp = 0 
! *** 2 PARAMETERS FOR Na (1 COMMON VALUE)
!     Na-H
      nalp = nalp + 1 
      iaf(nalp) = 1 
      ial(nalp) = 11 
      alpb(nalp) = 1.05225212D0 
!     Na-C
      nalp = nalp + 1 
      iaf(nalp) = 6 
      ial(nalp) = 11 
      alpb(nalp) = 1.05225212D0 
! *** 3 PARAMETERS FOR Mg (2 VALUES)
!     Mg-H
      nalp = nalp + 1 
      iaf(nalp) = 1 
      ial(nalp) = 12 
      alpb(nalp) = 1.35052992D0 
!     Mg-C
      nalp = nalp + 1 
      iaf(nalp) = 6 
      ial(nalp) = 12 
      alpb(nalp) = 1.48172071D0 
!     Mg-S
      nalp = nalp + 1 
      iaf(nalp) = 16 
      ial(nalp) = 12 
      alpb(nalp) = 1.48172071D0 
! *** 3 PARAMETERS FOR Al (1 COMMON VALUE)
!     Al-H
      nalp = nalp + 1 
      iaf(nalp) = 1 
      ial(nalp) = 13 
      alpb(nalp) = 1.38788000D0 
!     Al-C
      nalp = nalp + 1 
      iaf(nalp) = 6 
      ial(nalp) = 13 
      alpb(nalp) = 1.38788000D0 
!     Al-Al
      nalp = nalp + 1 
      iaf(nalp) = 13 
      ial(nalp) = 13 
      alpb(nalp) = 1.38788000D0 
      return  
      end subroutine mlig 


      real(kind(0.0d0)) function poij (l, d, fg) 
!-----------------------------------------------
!   M o d u l e s 
!-----------------------------------------------
      USE vast_kind_param, ONLY:  double 
      use funcon_C, only : ev
!     *
!     DETERMINE ADDITIVE TERMS RHO=POIJ FOR TWO-CENTER TWO-ELECTRON
!     INTEGRALS FROM THE REQUIREMENT THAT THE APPROPRIATE ONE-CENTER
!     TWO-ELECTRON INTEGRALS ARE REPRODUCED.
!     *
!...Translated by Pacific-Sierra Research 77to90  4.4G  12:41:19  03/10/06  
!...Switches: -rl INDDO=2 INDIF=2 
      implicit none
!-----------------------------------------------
!   D u m m y   A r g u m e n t s
!-----------------------------------------------
      integer , intent(in) :: l 
      real(double) , intent(in) :: d 
      real(double) , intent(in) :: fg 
!-----------------------------------------------
!   L o c a l   P a r a m e t e r s
!-----------------------------------------------
      real(double), parameter :: epsil = 1.0D-08 
      real(double), parameter :: g1 = 0.382D0 
      real(double), parameter :: g2 = 0.618D0 
      integer, parameter :: niter = 100 
!-----------------------------------------------
!   L o c a l   V a r i a b l e s
!-----------------------------------------------
      integer :: i 
      real(double) :: dsq, ev4, ev8, a1, a2, delta, y1, y2, f1, f2 
!-----------------------------------------------
      if (l == 0) then 
        poij = 0.5d0*ev/fg 
        return  
      endif 
! *** HIGHER TERMS.
      dsq = d*d 
      ev4 = ev*0.25d0 
      ev8 = ev/8.0D0 
      a1 = 0.1D0 
      a2 = 5.0D0 
      if (l == 1) then 
        do i = 1, niter 
          delta = a2 - a1 
          if (delta < epsil) exit  
          y1 = a1 + delta*g1 
          y2 = a1 + delta*g2 
          f1 = (ev4*(1.d0/y1 - 1.d0/sqrt(y1**2 + dsq)) - fg)**2 
          f2 = (ev4*(1.d0/y2 - 1.d0/sqrt(y2**2 + dsq)) - fg)**2 
          if (f1 < f2) then 
            a2 = y2 
          else 
            a1 = y1 
          endif 
        end do 
      else 
        if (l == 2) then 
          do i = 1, niter 
            delta = a2 - a1 
            if (delta < epsil) exit  
            y1 = a1 + delta*g1 
            y2 = a1 + delta*g2 
            f1 = (ev8*(1.d0/y1 - 2.d0/sqrt(y1**2 + dsq*0.5d0) + 1.d0/sqrt(y1**2 + &
              dsq)) - fg)**2 
            f2 = (ev8*(1.d0/y2 - 2.d0/sqrt(y2**2 + dsq*0.5d0) + 1.d0/sqrt(y2**2 + &
              dsq)) - fg)**2 
            if (f1 < f2) then 
              a2 = y2 
            else 
              a1 = y1 
            endif 
          end do 
        else 
          do i = 1, niter 
            delta = a2 - a1 
            if (delta < epsil) exit  
            y1 = a1 + delta*g1 
            y2 = a1 + delta*g2 
            if (f1 < f2) then 
              a2 = y2 
            else 
              a1 = y1 
            endif 
          end do 
        endif 
      endif 
!     DEFINE ADDITIVE TERM AFTER CONVERGENCE OF ITERATIONS.
      if (f1 >= f2) then 
        poij = a2 
      else 
        poij = a1 
      endif 
      return  
      end function poij 


      subroutine printp(i, para, value, txt) 
!-----------------------------------------------
!   M o d u l e s 
!-----------------------------------------------
      USE vast_kind_param, ONLY:  double 
      USE chanel_C, only : iw 
!...Translated by Pacific-Sierra Research 77to90  4.4G  12:41:19  03/10/06  
!...Switches: -rl INDDO=2 INDIF=2 
      implicit none
!-----------------------------------------------
!   D u m m y   A r g u m e n t s
!-----------------------------------------------
      integer , intent(in) :: i 
      real(double) , intent(in) :: value 
      character , intent(in) :: para*(*) 
      character , intent(in) :: txt*(*) 
!-----------------------------------------------
!   L o c a l   V a r i a b l e s
!-----------------------------------------------
      if (abs(value) > 1.D-5) write (iw, '(I4,A7,2X,F13.8,2X,A)') i, para, &
        value, txt 
      return  
      end subroutine printp 


      subroutine prthco() 
!-----------------------------------------------
!   M o d u l e s 
!-----------------------------------------------
      use permanent_arrays, only : nlast, h
      use chanel_C, only : iw
      use molkst_C, only : numat, lm6
!***********************************************************************
!DECK MOPAC
!...Translated by Pacific-Sierra Research 77to90  4.4G  12:41:19  03/10/06  
!...Switches: -rl INDDO=2 INDIF=2 
!-----------------------------------------------
!   I n t e r f a c e   B l o c k s
!-----------------------------------------------
      use vecprt_I 
      implicit none
!-----------------------------------------------
!   L o c a l   V a r i a b l e s
!-----------------------------------------------
      integer :: i
!----------------------------------------------- 
      i = nlast(numat) 
      write (iw, '(A48,I6)') ' NUMBER OF BASIS ORBITALS', i 
!
!   This next line does not look right.
!
      write (iw, '(A48,I6)') ' NUMBER OF EIGENVECTORS COMPUTED', i 
      write (iw, '(A48,I6)') ' ROW DIMENSION OF SQUARE MATRICES IN SCF', i + 1 
      write (iw, '(A48,I6)') ' DIMENSION OF LOWER TRIANGLE MATRIX IN SCF', (i*(&
        i + 1))/2 
      write (iw, '(A48,I6)') ' NUMBER OF ONE-CENTER AO PAIRS', 0 
      write (iw, '(A48,I6)') ' NUMBER OF TWO-ELECTRON INTEGRALS', lm6**2 
      write (iw, '(A)') '     CORE HAMILTONIAN MATRIX H(LM4).' 
      call vecprt (h, (-nlast(numat))) 
!#      J=LM6**2
!#         WRITE(IW,'(//10X,''TWO-ELECTRON MATRIX IN HCORE''/)')
!#         WRITE(IW,180)(W(I),I=1,J)
!#  180 FORMAT(10F8.4)
      return  
      end subroutine prthco 


      subroutine prtpar 
!-----------------------------------------------
!   M o d u l e s 
!-----------------------------------------------  
      use permanent_arrays, only : nat
      use molkst_C, only : numat
      use chanel_C, only : iw
      USE parameters_C, only : alp, tore, uss, upp, udd, zs, zp, zd, zsn, &
      zpn, zdn, gpp, gp2, hsp, gss, gsp, eisol, eheat, betas, betap, betad, &
      po, ddp, f0dd, f2dd, f4dd, f0sd, g2sd, f0pd, f2pd, &
      & g1pd, g3pd
!***********************************************************************
!DECK MOPAC
!...Translated by Pacific-Sierra Research 77to90  4.4G  12:41:19  03/10/06  
!...Switches: -rl INDDO=2 INDIF=2 
!-----------------------------------------------
!   I n t e r f a c e   B l o c k s
!-----------------------------------------------
      use printp_I 
      implicit none
!-----------------------------------------------
!   L o c a l   V a r i a b l e s
!-----------------------------------------------
      integer , dimension(107) :: iused 
      integer ::  i 
!-----------------------------------------------
      iused = 0 
      iused(nat(:numat)) = 1 
      write (iw, *) 'PARAMETER VALUES USED IN THE CALCULATION' 
      write (iw, *) 
      write (iw, *) ' NI    TYPE        VALUE     UNIT' 
      write (iw, *) 
      do i = 1, 107 
        if (iused(i) == 0) cycle  
        write (iw, *) 
        call printp (i, 'USS  ', uss(i), 'EV        ONE-CENTER ENERGY FOR S') 
        call printp (i, 'UPP  ', upp(i), 'EV        ONE-CENTER ENERGY FOR P') 
        call printp (i, 'ZS   ', zs(i), 'AU        ORBITAL EXPONENT  FOR S') 
        call printp (i, 'ZP   ', zp(i), 'AU        ORBITAL EXPONENT  FOR P') 
        call printp (i, 'BETAS', betas(i), 'EV        BETA PARAMETER    FOR S') 
        call printp (i, 'BETAP', betap(i), 'EV        BETA PARAMETER    FOR P') 
        call printp (i, 'ALP  ', alp(i), '(1/A)     ALPHA PARAMETER   FOR CORE'&
          ) 
        call printp (i, 'GSS  ', gss(i), &
          'EV        ONE-CENTER INTEGRAL (SS,SS)') 
        call printp (i, 'GPP  ', gpp(i), &
          'EV        ONE-CENTER INTEGRAL (PP,PP)') 
        call printp (i, 'GSP  ', gsp(i), &
          'EV        ONE-CENTER INTEGRAL (SS,PP)') 
        call printp (i, 'GP2  ', gp2(i), &
          'EV        ONE-CENTER INTEGRAL (PP*,PP*)') 
        call printp (i, 'HSP  ', hsp(i), &
          'EV        ONE-CENTER INTEGRAL (SP,SP)') 
        call printp (i, 'UDD  ', udd(i), 'EV        ONE-CENTER ENERGY FOR D') 
        call printp (i, 'ZD   ', zd(i), 'AU        ORBITAL EXPONENT  FOR D') 
        call printp (i, 'BETAD', betad(i), 'EV        BETA PARAMETER    FOR D') 
        call printp (i, 'ZSN  ', zsn(i), &
          'AU        INTERNAL EXPONENT FOR S - (IJ,KL)') 
        call printp (i, 'ZPN  ', zpn(i), &
          'AU        INTERNAL EXPONENT FOR P - (IJ,KL)') 
        call printp (i, 'ZDN  ', zdn(i), &
          'AU        INTERNAL EXPONENT FOR D - (IJ,KL)') 
        call printp (i, 'F0DD ', f0dd(i), &
          'EV        SLATER-CONDON PARAMETER F0DD') 
        call printp (i, 'F2DD ', f2dd(i), &
          'EV        SLATER-CONDON PARAMETER F2DD') 
        call printp (i, 'F4DD ', f4dd(i), &
          'EV        SLATER-CONDON PARAMETER F4DD') 
        call printp (i, 'F0SD ', f0sd(i), &
          'EV        SLATER-CONDON PARAMETER F0SD') 
        call printp (i, 'G2SD ', g2sd(i), &
          'EV        SLATER-CONDON PARAMETER G2SD') 
        call printp (i, 'F0PD ', f0pd(i), &
          'EV        SLATER-CONDON PARAMETER F0PD') 
        call printp (i, 'F2PD ', f2pd(i), &
          'EV        SLATER-CONDON PARAMETER F2PD') 
        call printp (i, 'G1PD ', g1pd(i), &
          'EV        SLATER-CONDON PARAMETER G1PD') 
        call printp (i, 'G3PD ', g3pd(i), &
          'EV        SLATER-CONDON PARAMETER G3PD') 
        call printp (i, 'DD2  ', ddp(2,i), &
          'BOHR      CHARGE SEPARATION, SP, L=1') 
        call printp (i, 'DD3  ', ddp(3,i), &
          'BOHR      CHARGE SEPARATION, PP, L=2') 
        call printp (i, 'DD4  ', ddp(4,i), &
          'BOHR      CHARGE SEPARATION, SD, L=2') 
        call printp (i, 'DD5  ', ddp(5,i), &
          'BOHR      CHARGE SEPARATION, PD, L=1') 
        call printp (i, 'DD6  ', ddp(6,i), &
          'BOHR      CHARGE SEPARATION, DD, L=2') 
        call printp (i, 'PO1  ', po(1,i), &
          'BOHR      KLOPMAN-OHNO TERM, SS, L=0') 
        call printp (i, 'PO2  ', po(2,i), &
          'BOHR      KLOPMAN-OHNO TERM, SP, L=1') 
        call printp (i, 'PO3  ', po(3,i), &
          'BOHR      KLOPMAN-OHNO TERM, PP, L=2') 
        call printp (i, 'PO4  ', po(4,i), &
          'BOHR      KLOPMAN-OHNO TERM, SD, L=2') 
        call printp (i, 'PO5  ', po(5,i), &
          'BOHR      KLOPMAN-OHNO TERM, PD, L=1') 
        call printp (i, 'PO6  ', po(6,i), &
          'BOHR      KLOPMAN-OHNO TERM, DD, L=2') 
        call printp (i, 'PO7  ', po(7,i), &
          'BOHR      KLOPMAN-OHNO TERM, PP, L=0') 
        call printp (i, 'PO8  ', po(8,i), &
          'BOHR      KLOPMAN-OHNO TERM, DD, L=0') 
        call printp (i, 'PO9  ', po(9,i), 'BOHR      KLOPMAN-OHNO TERM, CORE') 
        call printp (i, 'CORE ', tore(i), 'E         CORE CHARGE') 
        call printp (i, 'EHEAT', eheat(i), &
          'KCAL/MOL  HEAT OF FORMATION OF THE ATOM (EXP)') 
        call printp (i, 'EISOL', eisol(i), &
          'EV        TOTAL ENERGY OF THE ATOM (CALC)') 
      end do 
      return  
      end subroutine prtpar 


      subroutine reppd(ni, nj, rij, ri) 
!-----------------------------------------------
!   M o d u l e s 
!-----------------------------------------------
      USE vast_kind_param, ONLY:  double 
      USE parameters_C, only : natorb, dd, qq, am, ad, aq
      use funcon_C, only : ev, a0 
!***********************************************************************
!
!..VECTOR VERSION WRITTEN BY ERNEST R. DAVIDSON, INDIANA UNIVERSITY
!
!
!  REPP CALCULATES THE TWO-ELECTRON REPULSION INTEGRALS AND THE
!       NUCLEAR ATTRACTION INTEGRALS.
!
!     ON INPUT RIJ     = INTERATOMIC DISTANCE
!              NI      = ATOM NUMBER OF FIRST ATOM
!              NJ      = ATOM NUMBER OF SECOND ATOM
!    (REF)     ADD     = ARRAY OF GAMMA, OR TWO-ELECTRON ONE-CENTER,
!                        INTEGRALS.
!    (REF)     TORE    = ARRAY OF NUCLEAR CHARGES OF THE ELEMENTS
!    (REF)     DD      = ARRAY OF DIPOLE CHARGE SEPARATIONS
!    (REF)     QQ      = ARRAY OF QUADRUPOLE CHARGE SEPARATIONS
!
!     THE COMMON BLOCKS ARE INITIALIZED IN BLOCK-DATA, AND NEVER CHANGED
!
!    ON OUTPUT RI      = ARRAY OF TWO-ELECTRON REPULSION INTEGRALS
!
!
! *** THIS ROUTINE COMPUTES THE 2.d0-CENTRE REPULSION INTEGRALS AND THE
! *** NUCLEAR ATTRACTION INTEGRALS.
! *** THE 2.d0-CENTRE REPULSION INTEGRALS (OVER LOCAL COORDINATES) ARE
! *** STORED AS FOLLOWS (WHERE P-SIGMA = O,  AND P-PI = P AND P* )
!     (SS/SS)=1,   (SO/SS)=2,   (OO/SS)=3,   (PP/SS)=4,   (SS/OS)=5,
!     (SO/SO)=6,   (SP/SP)=7,   (OO/SO)=8,   (PP/SO)=9,   (PO/SP)=10,
!     (SS/OO)=11,  (SS/PP)=12,  (SO/OO)=13,  (SO/PP)=14,  (SP/OP)=15,
!     (OO/OO)=16,  (PP/OO)=17,  (OO/PP)=18,  (PP/PP)=19,  (PO/PO)=20,
!     (PP/P*P*)=21,   (P*P/P*P)=22.
! *** NI AND NJ ARE THE ATOMIC NUMBERS OF THE 2.d0 ELEMENTS.
!
!***********************************************************************
!***********************************************************************
!DECK MOPAC
!...Translated by Pacific-Sierra Research 77to90  4.4G  12:41:19  03/10/06  
!...Switches: -rl INDDO=2 INDIF=2 
      implicit none
!-----------------------------------------------
!   D u m m y   A r g u m e n t s
!-----------------------------------------------
      integer , intent(in) :: ni 
      integer , intent(in) :: nj 
      real(double) , intent(in) :: rij 
      real(double) , intent(out) :: ri(22) 
!-----------------------------------------------
!   L o c a l   V a r i a b l e s
!-----------------------------------------------
      integer , dimension(22) :: nri 
      integer :: i 
      real(double), dimension(72) :: arg, sqr 
      real(double) :: td, pp, ev1, ev2, ev3, ev4, r, aee, da, qa, ade, aqe&
        , rsq, xxx, ee, db, qb, aed, aeq, axx, adq, aqd, aqq, yyy, zzz, www, &
        dze, qzze, qxxe, edz, eqzz, eqxx, dxdx, dzdz, dzqxx, qxxdz, dzqzz, &
        qzzdz, qxxqxx, qxxqyy, qxxqzz, qzzqxx, qzzqzz, dxqxz, qxzdx, qxzqxz
      logical :: si, sj 

      save td, pp 
!-----------------------------------------------

      data td/ 2.D00/  
      data pp/ 0.5D00/  
      data nri/ 1, -1, 1, 1, -1, 1, 1, -1, -1, -1, 1, 1, -1, -1, -1, 1, 1, 1, 1&
        , 1, 1, 1/  
      ev1 = ev/2 
      ev2 = ev1/2 
      ev3 = ev2/2 
      ev4 = ev3/2 
      ri = 0.D0 
      r = rij/a0
        si = natorb(ni) >= 3 
        sj = natorb(nj) >= 3 
!
        if (.not.si .and. .not.sj) then 
!
!     HYDROGEN - HYDROGEN  (SS/SS)
!
          aee = pp/am(ni) + pp/am(nj) 
          aee = aee*aee 
          ri(1) = ev/sqrt(r*r + aee) 
!
        else if (si .and. .not.sj) then 
!
!     HEAVY ATOM - HYDROGEN
!
          aee = pp/am(ni) + pp/am(nj) 
          aee = aee*aee 
          da = dd(ni) 
          qa = qq(ni)*td 
          ade = pp/ad(ni) + pp/am(nj) 
          ade = ade*ade 
          aqe = pp/aq(ni) + pp/am(nj) 
          aqe = aqe*aqe 
          rsq = r*r 
          arg(1) = rsq + aee 
          xxx = r + da 
          arg(2) = xxx*xxx + ade 
          xxx = r - da 
          arg(3) = xxx*xxx + ade 
          xxx = r + qa 
          arg(4) = xxx*xxx + aqe 
          xxx = r - qa 
          arg(5) = xxx*xxx + aqe 
          arg(6) = rsq + aqe 
          arg(7) = arg(6) + qa*qa 
          do i = 1, 7 
            sqr(i) = sqrt(arg(i)) 
          end do 
          ee = ev/sqr(1) 
          ri(1) = ee 
          ri(2) = ev1/sqr(2) - ev1/sqr(3) 
          ri(3) = ee + ev2/sqr(4) + ev2/sqr(5) - ev1/sqr(6) 
          ri(4) = ee + ev1/sqr(7) - ev1/sqr(6) 
!
        else if (.not.si .and. sj) then 
!
!     HYDROGEN - HEAVY ATOM
!
          aee = pp/am(ni) + pp/am(nj) 
          aee = aee*aee 
          db = dd(nj) 
          qb = qq(nj)*td 
          aed = pp/am(ni) + pp/ad(nj) 
          aed = aed*aed 
          aeq = pp/am(ni) + pp/aq(nj) 
          aeq = aeq*aeq 
          rsq = r*r 
          arg(1) = rsq + aee 
          xxx = r - db 
          arg(2) = xxx*xxx + aed 
          xxx = r + db 
          arg(3) = xxx*xxx + aed 
          xxx = r - qb 
          arg(4) = xxx*xxx + aeq 
          xxx = r + qb 
          arg(5) = xxx*xxx + aeq 
          arg(6) = rsq + aeq 
          arg(7) = arg(6) + qb*qb 
          do i = 1, 7 
            sqr(i) = sqrt(arg(i)) 
          end do 
          ee = ev/sqr(1) 
          ri(1) = ee 
          ri(5) = ev1/sqr(2) - ev1/sqr(3) 
          ri(11) = ee + ev2/sqr(4) + ev2/sqr(5) - ev1/sqr(6) 
          ri(12) = ee + ev1/sqr(7) - ev1/sqr(6) 
!
        else 
!
!     HEAVY ATOM - HEAVY ATOM
!
!     DEFINE CHARGE SEPARATIONS.
          da = dd(ni) 
          db = dd(nj) 
          qa = qq(ni)*td 
          qb = qq(nj)*td 
!
          aee = pp/am(ni) + pp/am(nj) 
          aee = aee*aee 
!
          ade = pp/ad(ni) + pp/am(nj) 
          ade = ade*ade 
          aqe = pp/aq(ni) + pp/am(nj) 
          aqe = aqe*aqe 
          aed = pp/am(ni) + pp/ad(nj) 
          aed = aed*aed 
          aeq = pp/am(ni) + pp/aq(nj) 
          aeq = aeq*aeq 
          axx = pp/ad(ni) + pp/ad(nj) 
          axx = axx*axx 
          adq = pp/ad(ni) + pp/aq(nj) 
          adq = adq*adq 
          aqd = pp/aq(ni) + pp/ad(nj) 
          aqd = aqd*aqd 
          aqq = pp/aq(ni) + pp/aq(nj) 
          aqq = aqq*aqq 
          rsq = r*r 
          arg(1) = rsq + aee 
          xxx = r + da 
          arg(2) = xxx*xxx + ade 
          xxx = r - da 
          arg(3) = xxx*xxx + ade 
          xxx = r - qa 
          arg(4) = xxx*xxx + aqe 
          xxx = r + qa 
          arg(5) = xxx*xxx + aqe 
          arg(6) = rsq + aqe 
          arg(7) = arg(6) + qa*qa 
          xxx = r - db 
          arg(8) = xxx*xxx + aed 
          xxx = r + db 
          arg(9) = xxx*xxx + aed 
          xxx = r - qb 
          arg(10) = xxx*xxx + aeq 
          xxx = r + qb 
          arg(11) = xxx*xxx + aeq 
          arg(12) = rsq + aeq 
          arg(13) = arg(12) + qb*qb 
          xxx = da - db 
          arg(14) = rsq + axx + xxx*xxx 
          xxx = da + db 
          arg(15) = rsq + axx + xxx*xxx 
          xxx = r + da - db 
          arg(16) = xxx*xxx + axx 
          xxx = r - da + db 
          arg(17) = xxx*xxx + axx 
          xxx = r - da - db 
          arg(18) = xxx*xxx + axx 
          xxx = r + da + db 
          arg(19) = xxx*xxx + axx 
          xxx = r + da 
          arg(20) = xxx*xxx + adq 
          arg(21) = arg(20) + qb*qb 
          xxx = r - da 
          arg(22) = xxx*xxx + adq 
          arg(23) = arg(22) + qb*qb 
          xxx = r - db 
          arg(24) = xxx*xxx + aqd 
          arg(25) = arg(24) + qa*qa 
          xxx = r + db 
          arg(26) = xxx*xxx + aqd 
          arg(27) = arg(26) + qa*qa 
          xxx = r + da - qb 
          arg(28) = xxx*xxx + adq 
          xxx = r - da - qb 
          arg(29) = xxx*xxx + adq 
          xxx = r + da + qb 
          arg(30) = xxx*xxx + adq 
          xxx = r - da + qb 
          arg(31) = xxx*xxx + adq 
          xxx = r + qa - db 
          arg(32) = xxx*xxx + aqd 
          xxx = r + qa + db 
          arg(33) = xxx*xxx + aqd 
          xxx = r - qa - db 
          arg(34) = xxx*xxx + aqd 
          xxx = r - qa + db 
          arg(35) = xxx*xxx + aqd 
          arg(36) = rsq + aqq 
          xxx = qa - qb 
          arg(37) = arg(36) + xxx*xxx 
          xxx = qa + qb 
          arg(38) = arg(36) + xxx*xxx 
          arg(39) = arg(36) + qa*qa 
          arg(40) = arg(36) + qb*qb 
          arg(41) = arg(39) + qb*qb 
          xxx = r - qb 
          arg(42) = xxx*xxx + aqq 
          arg(43) = arg(42) + qa*qa 
          xxx = r + qb 
          arg(44) = xxx*xxx + aqq 
          arg(45) = arg(44) + qa*qa 
          xxx = r + qa 
          arg(46) = xxx*xxx + aqq 
          arg(47) = arg(46) + qb*qb 
          xxx = r - qa 
          arg(48) = xxx*xxx + aqq 
          arg(49) = arg(48) + qb*qb 
          xxx = r + qa - qb 
          arg(50) = xxx*xxx + aqq 
          xxx = r + qa + qb 
          arg(51) = xxx*xxx + aqq 
          xxx = r - qa - qb 
          arg(52) = xxx*xxx + aqq 
          xxx = r - qa + qb 
          arg(53) = xxx*xxx + aqq 
          qa = qq(ni) 
          qb = qq(nj) 
          xxx = da - qb 
          xxx = xxx*xxx 
          yyy = r - qb 
          yyy = yyy*yyy 
          zzz = da + qb 
          zzz = zzz*zzz 
          www = r + qb 
          www = www*www 
          arg(54) = xxx + yyy + adq 
          arg(55) = xxx + www + adq 
          arg(56) = zzz + yyy + adq 
          arg(57) = zzz + www + adq 
          xxx = qa - db 
          xxx = xxx*xxx 
          yyy = qa + db 
          yyy = yyy*yyy 
          zzz = r + qa 
          zzz = zzz*zzz 
          www = r - qa 
          www = www*www 
          arg(58) = zzz + xxx + aqd 
          arg(59) = www + xxx + aqd 
          arg(60) = zzz + yyy + aqd 
          arg(61) = www + yyy + aqd 
          xxx = qa - qb 
          xxx = xxx*xxx 
          arg(62) = arg(36) + td*xxx 
          yyy = qa + qb 
          yyy = yyy*yyy 
          arg(63) = arg(36) + td*yyy 
          arg(64) = arg(36) + td*(qa*qa + qb*qb) 
          zzz = r + qa - qb 
          zzz = zzz*zzz 
          arg(65) = zzz + xxx + aqq 
          arg(66) = zzz + yyy + aqq 
          zzz = r + qa + qb 
          zzz = zzz*zzz 
          arg(67) = zzz + xxx + aqq 
          arg(68) = zzz + yyy + aqq 
          zzz = r - qa - qb 
          zzz = zzz*zzz 
          arg(69) = zzz + xxx + aqq 
          arg(70) = zzz + yyy + aqq 
          zzz = r - qa + qb 
          zzz = zzz*zzz 
          arg(71) = zzz + xxx + aqq 
          arg(72) = zzz + yyy + aqq 
          do i = 1, 72 
            sqr(i) = sqrt(arg(i)) 
          end do 
          ee = ev/sqr(1) 
          dze = (-ev1/sqr(2)) + ev1/sqr(3) 
          qzze = ev2/sqr(4) + ev2/sqr(5) - ev1/sqr(6) 
          qxxe = ev1/sqr(7) - ev1/sqr(6) 
          edz = (-ev1/sqr(8)) + ev1/sqr(9) 
          eqzz = ev2/sqr(10) + ev2/sqr(11) - ev1/sqr(12) 
          eqxx = ev1/sqr(13) - ev1/sqr(12) 
          dxdx = ev1/sqr(14) - ev1/sqr(15) 
          dzdz = ev2/sqr(16) + ev2/sqr(17) - ev2/sqr(18) - ev2/sqr(19) 
          dzqxx = ev2/sqr(20) - ev2/sqr(21) - ev2/sqr(22) + ev2/sqr(23) 
          qxxdz = ev2/sqr(24) - ev2/sqr(25) - ev2/sqr(26) + ev2/sqr(27) 
          dzqzz = (-ev3/sqr(28)) + ev3/sqr(29) - ev3/sqr(30) + ev3/sqr(31) - &
            ev2/sqr(22) + ev2/sqr(20) 
          qzzdz = (-ev3/sqr(32)) + ev3/sqr(33) - ev3/sqr(34) + ev3/sqr(35) + &
            ev2/sqr(24) - ev2/sqr(26) 
          qxxqxx = ev3/sqr(37) + ev3/sqr(38) - ev2/sqr(39) - ev2/sqr(40) + ev2/&
            sqr(36) 
          qxxqyy = ev2/sqr(41) - ev2/sqr(39) - ev2/sqr(40) + ev2/sqr(36) 
          qxxqzz = ev3/sqr(43) + ev3/sqr(45) - ev3/sqr(42) - ev3/sqr(44) - ev2/&
            sqr(39) + ev2/sqr(36) 
          qzzqxx = ev3/sqr(47) + ev3/sqr(49) - ev3/sqr(46) - ev3/sqr(48) - ev2/&
            sqr(40) + ev2/sqr(36) 
          qzzqzz = ev4/sqr(50) + ev4/sqr(51) + ev4/sqr(52) + ev4/sqr(53) - ev3/&
            sqr(48) - ev3/sqr(46) - ev3/sqr(42) - ev3/sqr(44) + ev2/sqr(36) 
          dxqxz = (-ev2/sqr(54)) + ev2/sqr(55) + ev2/sqr(56) - ev2/sqr(57) 
          qxzdx = (-ev2/sqr(58)) + ev2/sqr(59) + ev2/sqr(60) - ev2/sqr(61) 
          qxzqxz = ev3/sqr(65) - ev3/sqr(67) - ev3/sqr(69) + ev3/sqr(71) - ev3/&
            sqr(66) + ev3/sqr(68) + ev3/sqr(70) - ev3/sqr(72) 
          ri(1) = ee 
          ri(2) = -dze 
          ri(3) = ee + qzze 
          ri(4) = ee + qxxe 
          ri(5) = -edz 
          ri(6) = dzdz 
          ri(7) = dxdx 
          ri(8) = (-edz) - qzzdz 
          ri(9) = (-edz) - qxxdz 
          ri(10) = -qxzdx 
          ri(11) = ee + eqzz 
          ri(12) = ee + eqxx 
          ri(13) = (-dze) - dzqzz 
          ri(14) = (-dze) - dzqxx 
          ri(15) = -dxqxz 
          ri(16) = ee + eqzz + qzze + qzzqzz 
          ri(17) = ee + eqzz + qxxe + qxxqzz 
          ri(18) = ee + eqxx + qzze + qzzqxx 
          ri(19) = ee + eqxx + qxxe + qxxqxx 
          ri(20) = qxzqxz 
          ri(21) = ee + eqxx + qxxe + qxxqyy 
          ri(22) = pp*(qxxqxx - qxxqyy) 
!
        endif 
!
        ri = ri*nri 
        return  
      end subroutine reppd 


      subroutine reppd2(ni, nj, r, ri, rep, core) 
!-----------------------------------------------
!   M o d u l e s 
!-----------------------------------------------
      USE vast_kind_param, ONLY:  double  
      use parameters_C, only : tore, dorbs 
      use mndod_C, only : index, ind2, isym
      use funcon_C, only : ev
!...Translated by Pacific-Sierra Research 77to90  4.4G  12:41:19  03/10/06  
!...Switches: -rl INDDO=2 INDIF=2 
!-----------------------------------------------
!   I n t e r f a c e   B l o c k s
!-----------------------------------------------
      use rijkl_I 
      implicit none
!-----------------------------------------------
!   D u m m y   A r g u m e n t s
!-----------------------------------------------
      integer  :: ni 
      integer  :: nj 
      real(double)  :: r 
      real(double) , intent(in) :: ri(22) 
      real(double) , intent(out) :: rep(491) 
      real(double) , intent(out) :: core(10,2)  
!-----------------------------------------------
!   L o c a l   V a r i a b l e s
!-----------------------------------------------
      integer , dimension(9) :: lorb 
      integer , dimension(34) :: ipos 
      integer :: i, lasti, lastk, li, j, lj, ij, k, lk, l, ll, kl, numb, &
        nold 
!-----------------------------------------------
!     *
!     LOCAL TWO-CENTER TWO-ELECTRON INTEGRALS (SPD)
!     * 
      data ipos/ 1, 5, 11, 12, 12, 2, 6, 13, 14, 14, 3, 8, 16, 18, 18, 7, 15, &
        10, 20, 4, 9, 17, 19, 21, 7, 15, 10, 20, 22, 4, 9, 17, 21, 19/  
      data lorb/ 0, 3*1, 5*2/  
!
      rep(:34) = ri(ipos) 
      if (dorbs(ni) .or. dorbs(nj)) then 
        if (dorbs(ni)) then 
          lasti = 9 
        else if (ni < 3) then 
          lasti = 1 
        else 
          lasti = 4 
        endif 
!
        if (dorbs(nj)) then 
          lastk = 9 
        else if (nj < 3) then 
          lastk = 1 
        else 
          lastk = 4 
        endif 
!
        do i = 1, lasti 
          li = lorb(i) 
          do j = 1, i 
            lj = lorb(j) 
            ij = index(i,j) 
!
            do k = 1, lastk 
              lk = lorb(k) 
              do l = 1, k 
                ll = lorb(l) 
                kl = index(k,l) 
!
                numb = ind2(ij,kl) 
                if (numb <= 34) cycle  
                nold = isym(numb) 
                select case (nold)  
                case (35:)  
                  rep(numb) = rep(nold) 
                case (:(-35))  
                  rep(numb) = -rep((-nold)) 
                case (0)  
                  rep(numb) = rijkl(ni,nj,ij,kl,li,lj,lk,ll,0,r)*ev 
                end select 
!
!      WRITE(11,'(I3,6X,''INT2C('',I2,'','',I2,'') ='',I5)')
!    -    NUMB,IJ,KL,NSYM
!       WRITE(11,'(6X,''INT2C('',I2,'','',I2,'') ='',I5)')IJ,KL,NSYM
!            IND2(IJ,KL) = NUMB
!            WRITE(6,'(2X,I4,'' <'',I2,I2,''|'',I2,I2,''>'',F12.4)')
!    -                  NUMB ,       I, J,       K, L,      REP(NUMB)
!
              end do 
            end do 
          end do 
        end do 
!
        core(5:10,1) = 0.D0 
        core(5:10,2) = 0.D0 
!
        if (dorbs(nj)) then 
! --- <S S | D S>
          kl = index(5,1) 
          core(5,2) = -rijkl(ni,nj,ij,kl,0,0,2,0,1,r)*ev*tore(ni) 
! --- <S S | D P >
          kl = index(5,2) 
          core(6,2) = -rijkl(ni,nj,ij,kl,0,0,2,1,1,r)*ev*tore(ni) 
! --- <S S | D D >
          kl = index(5,5) 
          core(7,2) = -rijkl(ni,nj,ij,kl,0,0,2,2,1,r)*ev*tore(ni) 
! --- <S S | D+P+>
          kl = index(6,3) 
          core(8,2) = -rijkl(ni,nj,ij,kl,0,0,2,1,1,r)*ev*tore(ni) 
! --- <S S | D+D+>
          kl = index(6,6) 
          core(9,2) = -rijkl(ni,nj,ij,kl,0,0,2,2,1,r)*ev*tore(ni) 
! --- <S S | D#D#>
          kl = index(8,8) 
          core(10,2) = -rijkl(ni,nj,ij,kl,0,0,2,2,1,r)*ev*tore(ni) 
        endif 
!*
        if (dorbs(ni)) then 
! --- <D S | S S>
          kl = index(5,1) 
          core(5,1) = -rijkl(ni,nj,kl,ij,2,0,0,0,2,r)*ev*tore(nj) 
! --- <D P | S S >
          kl = index(5,2) 
          core(6,1) = -rijkl(ni,nj,kl,ij,2,1,0,0,2,r)*ev*tore(nj) 
! --- <D D | S S >
          kl = index(5,5) 
          core(7,1) = -rijkl(ni,nj,kl,ij,2,2,0,0,2,r)*ev*tore(nj) 
! --- <D+P+| S S >
          kl = index(6,3) 
          core(8,1) = -rijkl(ni,nj,kl,ij,2,1,0,0,2,r)*ev*tore(nj) 
! --- <D+D+| S S >
          kl = index(6,6) 
          core(9,1) = -rijkl(ni,nj,kl,ij,2,2,0,0,2,r)*ev*tore(nj) 
! --- <D#D#| S S >
          kl = index(8,8) 
          core(10,1) = -rijkl(ni,nj,kl,ij,2,2,0,0,2,r)*ev*tore(nj) 
!
        endif 
      endif 
!*    WRITE(6,'('' DCORE:'',/(2X,6F12.4))') CORE
      return  
      end subroutine reppd2 


      real(kind(0.0d0)) function rijkl (ni, nj, ij, kl, li, lj, lk, ll, ic, r) 
!-----------------------------------------------
!   M o d u l e s 
!-----------------------------------------------
      USE vast_kind_param, ONLY:  double 
      use parameters_C, only : ddp, po
      use mndod_C, only : indx, ch
!...Translated by Pacific-Sierra Research 77to90  4.4G  12:41:19  03/10/06  
!...Switches: -rl INDDO=2 INDIF=2 
!-----------------------------------------------
!   I n t e r f a c e   B l o c k s
!-----------------------------------------------
      use charg_I 
      implicit none
!-----------------------------------------------
!   D u m m y   A r g u m e n t s
!-----------------------------------------------
      integer , intent(in) :: ni 
      integer , intent(in) :: nj 
      integer , intent(in) :: ij 
      integer , intent(in) :: kl 
      integer , intent(in) :: li 
      integer , intent(in) :: lj 
      integer , intent(in) :: lk 
      integer , intent(in) :: ll 
      integer , intent(in) :: ic 
      real(double)  :: r 
!-----------------------------------------------
!   L o c a l   V a r i a b l e s
!-----------------------------------------------
      integer :: l1min, l1max, lij, l2min, l2max, lkl, l1, l2, lmin, m, mm 
      real(double) :: sum, pij, dij, pkl, dkl, add, s1, ccc 
!-----------------------------------------------
!     *
!
      l1min = iabs(li - lj) 
      l1max = li + lj 
      lij = indx(li+1,lj+1) 
      l2min = iabs(lk - ll) 
      l2max = lk + ll 
      lkl = indx(lk+1,ll+1) 
      l1max = min(l1max,2) 
      l1min = min(l1min,2) 
      l2max = min(l2max,2) 
      l2min = min(l2min,2) 
      sum = 0.D00 
!
      do l1 = l1min, l1max 
        if (l1 == 0) then 
          select case (lij)  
          case (1)  
            pij = po(1,ni) 
            if (ic == 1) pij = po(9,ni) 
          case (3)  
            pij = po(7,ni) 
          case (6)  
            pij = po(8,ni) 
          end select 
        else 
          dij = ddp(lij,ni) 
          pij = po(lij,ni) 
        endif 
!
        do l2 = l2min, l2max 
          if (l2 == 0) then 
            select case (lkl)  
            case (1)  
              pkl = po(1,nj) 
              if (ic == 2) pkl = po(9,nj) 
            case (3)  
              pkl = po(7,nj) 
            case (6)  
              pkl = po(8,nj) 
            end select 
          else 
            dkl = ddp(lkl,nj) 
            pkl = po(lkl,nj) 
          endif 
!
          add = (pij + pkl)**2 
          lmin = min(l1,l2) 
          s1 = 0.D00 
          do m = -lmin, lmin 
            ccc = ch(ij,l1,m)*ch(kl,l2,m) 
            if (ccc == 0.000) cycle  
            mm = iabs(m) 
            s1 = s1 + charg(r,l1,l2,mm,dij,dkl,add)*ccc 
          end do 
          sum = sum + s1 
        end do 
      end do 
!
      rijkl = sum 
      return  
      end function rijkl 


      subroutine rotatd(ip, jp, ia, ib, ja, jb, ni, nj, ci, cj, w, lm6, enuc) 
!-----------------------------------------------
!   M o d u l e s 
!-----------------------------------------------
      USE vast_kind_param, ONLY:  double 
      use funcon_C, only : a0
      use mndod_C, only : indx, index, sp, sd, pp, dp, dd, cored, inddd    
!     *
!     CALCULATION OF TWO-CENTER TWO-ELECTRON INTEGRALS
!     IN THE MOLECULAR COODINATE SYSTEM BY 2.d0-STEP PROCEDURE
!     *
!***********************************************************************
!DECK MOPAC
!...Translated by Pacific-Sierra Research 77to90  4.4G  12:41:19  03/10/06  
!...Switches: -rl INDDO=2 INDIF=2 
!-----------------------------------------------
!   I n t e r f a c e   B l o c k s
!-----------------------------------------------
      use rotmat_I 
      use reppd_I 
      use spcore_I 
      use reppd2_I 
      use tx_I 
      use w2mat_I 
      use ccrep_I 
      implicit none
!-----------------------------------------------
!   G l o b a l   P a r a m e t e r s
!-----------------------------------------------
!-----------------------------------------------
!   D u m m y   A r g u m e n t s
!-----------------------------------------------
      integer  :: ip 
      integer  :: jp 
      integer , intent(in) :: ia 
      integer , intent(in) :: ib 
      integer , intent(in) :: ja 
      integer , intent(in) :: jb 
      integer  :: ni 
      integer  :: nj 
      integer  :: lm6 
      real(double)  :: ci(3) 
      real(double)  :: cj(3)
      real(double), dimension(*)  :: w 
      real(double)  :: enuc 
!-----------------------------------------------
!   L o c a l   V a r i a b l e s
!-----------------------------------------------
      integer , dimension(45) :: met 
      integer :: limkl, kl, ii, kk, limij, istep, i, i1, j1, ij, jj, mm, k, l, &
        iw, iminus, j, ij1, jw 
      real(double), dimension(45,45) :: v 
      real(double), dimension(22) :: ri 
      real(double), dimension(491) :: rep 
      real(double), dimension(2025) :: ww 
      real(double) :: r, wrepp, cc 
      logical, dimension(45,45) :: logv 
!-----------------------------------------------
!
      data met/ 1, 2, 3, 2, 3, 3, 2, 3, 3, 3, 4, 5, 5, 5, 6, 4, 5, 5, 5, 6, 6, &
        4, 5, 5, 5, 6, 6, 6, 4, 5, 5, 5, 6, 6, 6, 6, 4, 5, 5, 5, 5*6/  
!
      call rotmat (nj, ni, ci, cj, r) 
!
      call reppd (ni, nj, r, ri) 
      r = r/a0 
      call spcore (ni, nj, r, cored) 
      call reppd2 (ni, nj, r, ri, rep, cored) 
!
      ii = ib - ia + 1 
      kk = jb - ja + 1 
      limij = indx(ii,ii) 
      limkl = indx(kk,kk) 
      istep = limkl*limij 
      ww(:istep) = 0.0D0 
!
      call tx (ii, kk, rep, logv, v) 
!
      do i1 = 1, ii 
        do j1 = 1, i1 
!
          ij = index(i1,j1) 
          jj = indx(i1,j1) 
          mm = met(jj) 
!
          do k = 1, kk 
            do l = 1, k 
              kl = indx(k,l) 
              if (.not.logv(ij,kl)) cycle  
              wrepp = v(ij,kl) 
!     GO TO (1,2,3,4,5,6),MM
!
              select case (mm)  
              case (1)  
                iw = indw(1,1) 
                ww(iw) = wrepp 
              case (2)  
                do i = 1, 3 
                  iw = indw(i + 1,1) 
                  ww(iw) = ww(iw) + sp(i1-1,i)*wrepp 
                end do 
              case (3)  
                do i = 1, 3 
                  cc = pp(i,i1-1,j1-1) 
                  iw = indw(i + 1,i + 1) 
                  ww(iw) = ww(iw) + cc*wrepp 
                  iminus = i - 1 
                  if (iminus == 0) cycle  
                  do j = 1, iminus 
                    cc = pp(1+i+j,i1-1,j1-1) 
                    iw = indw(i + 1,j + 1) 
                    ww(iw) = ww(iw) + cc*wrepp 
                  end do 
                end do 
              case (4)  
                do i = 1, 5 
                  iw = indw(i + 4,1) 
                  ww(iw) = ww(iw) + sd(i1-4,i)*wrepp 
                end do 
              case (5)  
                do i = 1, 5 
                  do j = 1, 3 
                    iw = indw(i + 4,j + 1) 
                    ij1 = 3*(i - 1) + j 
                    ww(iw) = ww(iw) + dp(ij1,i1-4,j1-1)*wrepp 
                  end do 
                end do 
              case (6)  
                do i = 1, 5 
                  cc = dd(i,i1-4,j1-4) 
                  iw = indw(i + 4,i + 4) 
                  ww(iw) = ww(iw) + cc*wrepp 
                  iminus = i - 1 
                  if (iminus == 0) cycle  
                  do j = 1, iminus 
                    ij1 = inddd(i,j) 
                    cc = dd(ij1,i1-4,j1-4) 
                    iw = indw(i + 4,j + 4) 
                    ww(iw) = ww(iw) + cc*wrepp 
                  end do 
                end do 
              end select 
!
            end do 
          end do 
        end do 
      end do 
      iw = ib - ia + 1 
      iw = (iw*(iw + 1))/2  
      jw = jb - ja + 1 
      jw = (jw*(jw + 1))/2 
      call w2mat (ip, jp, ww, w, lm6, iw, jw) 
! *** CORE-CORE REPULSIONS FOR MNDO.
      call ccrep (ni, nj, r, enuc) 
      return  
      contains 


      integer function indw (i, j) 
      integer, intent(in) :: i 
      integer, intent(in) :: j 
      indw = (indx(i,j)-1)*limkl + kl 
      return  
      end function indw 
      end subroutine rotatd 


      subroutine rotmat(nj, ni, coordi, coordj, r) 
!-----------------------------------------------
!   M o d u l e s 
!-----------------------------------------------
      USE vast_kind_param, ONLY:  double 
      use parameters_C, only : dorbs
      use mndod_C, only : sp, pp, sd, dp, dd
!     *
!     ROTATION MATRIX FOR A GIVEN ATOM PAIR I-J (I.GT.J).
!     *
!...Translated by Pacific-Sierra Research 77to90  4.4G  12:41:19  03/10/06  
!...Switches: -rl INDDO=2 INDIF=2 
      implicit none
!-----------------------------------------------
!   D u m m y   A r g u m e n t s
!-----------------------------------------------
      integer , intent(in) :: nj 
      integer , intent(in) :: ni 
      real(double) , intent(out) :: r 
      real(double) , intent(in) :: coordi(3) 
      real(double) , intent(in) :: coordj(3) 
!-----------------------------------------------
!   L o c a l   P a r a m e t e r s
!-----------------------------------------------
      real(double), parameter :: small = 1.0D-07 
      real(double), parameter :: pt5sq3 = 0.8660254037841D0 
!-----------------------------------------------
!   L o c a l   V a r i a b l e s
!-----------------------------------------------
      integer :: k
      real(double), dimension(3,3) :: p 
      real(double), dimension(5,5) :: d 
      real(double) :: x11, x22, x33, b, sqb, sb, ca, sa, cb, c2a, c2b, s2a, s2b 
!-----------------------------------------------
! *** CALCULATE GEOMETRIC DATA AND INTERATOMIC DISTANCE.
!     CA  = COS(PHI)    , SA  = SIN(PHI)
!     CB  = COS(THETA)  , SB  = SIN(THETA)
!     C2A = COS(2*PHI)  , S2A = SIN(2*PHI)
!     C2B = COS(2*THETA), S2B = SIN(2*PHI)
      x11 = coordj(1) - coordi(1) 
      x22 = coordj(2) - coordi(2) 
      x33 = coordj(3) - coordi(3) 
      b = x11*x11 + x22*x22 
      r = sqrt(b + x33*x33) 
      sqb = sqrt(b) 
      sb = sqb/r 
!     CHECK FOR SPECIAL CASE (BOTH ATOMS ON Z AXIS).
      if (sb > small) then 
        ca = x11/sqb 
        sa = x22/sqb 
        cb = x33/r 
      else 
        sa = 0.d0 
        sb = 0.d0 
        if (x33 < 0.d0) then 
          ca = -1.d0 
          cb = -1.d0 
        else if (x33 > 0.d0) then 
          ca = 1.d0 
          cb = 1.d0 
        else 
          ca = 0.d0 
          cb = 0.d0 
        endif 
      endif 
!     CONVERT DISTANCE TO ATOMIC UNITS.
!#      R      = R/A0
! *** CALCULATE ROTATION MATRIX ELEMENTS.
      p(1,1) = ca*sb 
      p(2,1) = ca*cb 
      p(3,1) = -sa 
      p(1,2) = sa*sb 
      p(2,2) = sa*cb 
      p(3,2) = ca 
      p(1,3) = cb 
      p(2,3) = -sb 
      p(3,3) = 0.d0 
      if (dorbs(ni) .or. dorbs(nj)) then 
        c2a = 2.d0*ca*ca - 1.d0 
        c2b = 2.d0*cb*cb - 1.d0 
        s2a = 2.d0*sa*ca 
        s2b = 2.d0*sb*cb 
        d(1,1) = pt5sq3*c2a*sb*sb 
        d(2,1) = 0.5d0*c2a*s2b 
        d(3,1) = -s2a*sb 
        d(4,1) = c2a*(cb*cb + 0.5d0*sb*sb) 
        d(5,1) = -s2a*cb 
        d(1,2) = pt5sq3*ca*s2b 
        d(2,2) = ca*c2b 
        d(3,2) = -sa*cb 
        d(4,2) = -0.5d0*ca*s2b 
        d(5,2) = sa*sb 
        d(1,3) = cb*cb - 0.5d0*sb*sb 
        d(2,3) = -pt5sq3*s2b 
        d(3,3) = 0.d0 
        d(4,3) = pt5sq3*sb*sb 
        d(5,3) = 0.d0 
        d(1,4) = pt5sq3*sa*s2b 
        d(2,4) = sa*c2b 
        d(3,4) = ca*cb 
        d(4,4) = -0.5d0*sa*s2b 
        d(5,4) = -ca*sb 
        d(1,5) = pt5sq3*s2a*sb*sb 
        d(2,5) = 0.5d0*s2a*s2b 
        d(3,5) = c2a*sb 
        d(4,5) = s2a*(cb*cb + 0.5d0*sb*sb) 
        d(5,5) = c2a*cb 
      endif 
!     *
!
!  S-P
      sp = p 
!  P-P
!     DATA INDPP /1,4,5,4,2,6,5,6,3/
!     DATA INDDP /1,4,7,10,13,2,5,8,11,14,3,6,9,12,15/
      do k = 1, 3 
        pp(1,k,k) = p(k,1)*p(k,1) 
        pp(2,k,k) = p(k,2)*p(k,2) 
        pp(3,k,k) = p(k,3)*p(k,3) 
        pp(4,k,k) = p(k,1)*p(k,2) 
        pp(5,k,k) = p(k,1)*p(k,3) 
        pp(6,k,k) = p(k,2)*p(k,3) 
        if (k == 1) cycle  
        pp(1,k,:k-1) = 2.D0*p(k,1)*p(:k-1,1) 
        pp(2,k,:k-1) = 2.D0*p(k,2)*p(:k-1,2) 
        pp(3,k,:k-1) = 2.D0*p(k,3)*p(:k-1,3) 
        pp(4,k,:k-1) = p(k,1)*p(:k-1,2) + p(k,2)*p(:k-1,1) 
        pp(5,k,:k-1) = p(k,1)*p(:k-1,3) + p(k,3)*p(:k-1,1) 
        pp(6,k,:k-1) = p(k,2)*p(:k-1,3) + p(k,3)*p(:k-1,2) 
      end do 
!
      if (dorbs(ni) .or. dorbs(nj)) then 
!  S-D
        sd = d 
!  D-P
        do k = 1, 5 
          dp(1,k,:) = d(k,1)*p(:,1) 
          dp(2,k,:) = d(k,1)*p(:,2) 
          dp(3,k,:) = d(k,1)*p(:,3) 
          dp(4,k,:) = d(k,2)*p(:,1) 
          dp(5,k,:) = d(k,2)*p(:,2) 
          dp(6,k,:) = d(k,2)*p(:,3) 
          dp(7,k,:) = d(k,3)*p(:,1) 
          dp(8,k,:) = d(k,3)*p(:,2) 
          dp(9,k,:) = d(k,3)*p(:,3) 
          dp(10,k,:) = d(k,4)*p(:,1) 
          dp(11,k,:) = d(k,4)*p(:,2) 
          dp(12,k,:) = d(k,4)*p(:,3) 
          dp(13,k,:) = d(k,5)*p(:,1) 
          dp(14,k,:) = d(k,5)*p(:,2) 
          dp(15,k,:) = d(k,5)*p(:,3) 
        end do 
!  D-D
        do k = 1, 5 
          dd(1,k,k) = d(k,1)*d(k,1) 
          dd(2,k,k) = d(k,2)*d(k,2) 
          dd(3,k,k) = d(k,3)*d(k,3) 
          dd(4,k,k) = d(k,4)*d(k,4) 
          dd(5,k,k) = d(k,5)*d(k,5) 
          dd(6,k,k) = d(k,1)*d(k,2) 
          dd(7,k,k) = d(k,1)*d(k,3) 
          dd(8,k,k) = d(k,2)*d(k,3) 
          dd(9,k,k) = d(k,1)*d(k,4) 
          dd(10,k,k) = d(k,2)*d(k,4) 
          dd(11,k,k) = d(k,3)*d(k,4) 
          dd(12,k,k) = d(k,1)*d(k,5) 
          dd(13,k,k) = d(k,2)*d(k,5) 
          dd(14,k,k) = d(k,3)*d(k,5) 
          dd(15,k,k) = d(k,4)*d(k,5) 
          if (k == 1) cycle  
          dd(1,k,:k-1) = 2.D0*d(k,1)*d(:k-1,1) 
          dd(2,k,:k-1) = 2.D0*d(k,2)*d(:k-1,2) 
          dd(3,k,:k-1) = 2.D0*d(k,3)*d(:k-1,3) 
          dd(4,k,:k-1) = 2.D0*d(k,4)*d(:k-1,4) 
          dd(5,k,:k-1) = 2.D0*d(k,5)*d(:k-1,5) 
          dd(6,k,:k-1) = d(k,1)*d(:k-1,2) + d(k,2)*d(:k-1,1) 
          dd(7,k,:k-1) = d(k,1)*d(:k-1,3) + d(k,3)*d(:k-1,1) 
          dd(8,k,:k-1) = d(k,2)*d(:k-1,3) + d(k,3)*d(:k-1,2) 
          dd(9,k,:k-1) = d(k,1)*d(:k-1,4) + d(k,4)*d(:k-1,1) 
          dd(10,k,:k-1) = d(k,2)*d(:k-1,4) + d(k,4)*d(:k-1,2) 
          dd(11,k,:k-1) = d(k,3)*d(:k-1,4) + d(k,4)*d(:k-1,3) 
          dd(12,k,:k-1) = d(k,1)*d(:k-1,5) + d(k,5)*d(:k-1,1) 
          dd(13,k,:k-1) = d(k,2)*d(:k-1,5) + d(k,5)*d(:k-1,2) 
          dd(14,k,:k-1) = d(k,3)*d(:k-1,5) + d(k,5)*d(:k-1,3) 
          dd(15,k,:k-1) = d(k,4)*d(:k-1,5) + d(k,5)*d(:k-1,4) 
        end do 
      endif 
      return  
      end subroutine rotmat 


      real(kind(0.0d0)) function rsc (k, na, ea, nb, eb, nc, ec, nd, ed) 
!-----------------------------------------------
!   M o d u l e s 
!-----------------------------------------------
      USE vast_kind_param, ONLY:  double 
      USE mndod_C, only : fx, b
      use funcon_C, only : ev
!     *
!     CALCULATE THE RADIAL PART OF ONE-CENTER TWO-ELECTRON INTEGRALS
!     (SLATER-CONDON PARAMETER)
!     K- TYPE OF INTEGRAL ,   CAN BE EQUAL TO 0,1,2,3,4 IN SPD-BASIS
!     NA,NB -PRINCIPLE QUANTUM NUMBER OF AO,CORRESPONDING ELECTRON 1
!     EA,EB -EXPONENTS OF AO,CORRESPONDING ELECTRON 1
!     NC,ND -PRINCIPLE QUANTUM NUMBER OF AO,CORRESPONDING ELECTRON 2
!     EC,ED -EXPONENTS OF AO,CORRESPONDING ELECTRON 2
!     *
!...Translated by Pacific-Sierra Research 77to90  4.4G  12:41:19  03/10/06  
!...Switches: -rl INDDO=2 INDIF=2 
      implicit none
!-----------------------------------------------
!   D u m m y   A r g u m e n t s
!-----------------------------------------------
      integer , intent(in) :: k 
      integer , intent(in) :: na 
      integer , intent(in) :: nb 
      integer , intent(in) :: nc 
      integer , intent(in) :: nd 
      real(double) , intent(in) :: ea 
      real(double) , intent(in) :: eb 
      real(double) , intent(in) :: ec 
      real(double) , intent(in) :: ed 
!-----------------------------------------------
!   L o c a l   V a r i a b l e s
!-----------------------------------------------
      integer :: nab, ncd, n, m, i, m1, m2 
      real(double) :: aea, aeb, aec, aed, ecd, eab, e, ae, a2, acd, aab, ff&
        , c, s0, s1, s2, s3 
!-----------------------------------------------
      aea = log(ea) 
      aeb = log(eb) 
      aec = log(ec) 
      aed = log(ed) 
      nab = na + nb 
      ncd = nc + nd 
      ecd = ec + ed 
      eab = ea + eb 
      e = ecd + eab 
      n = nab + ncd 
      ae = log(e) 
      a2 = log(2.d0) 
      acd = log(ecd) 
      aab = log(eab) 
      ff = fx(n)/sqrt(fx(2*na+1)*fx(2*nb+1)*fx(2*nc+1)*fx(2*nd+1)) 
      c = ev*ff*exp(na*aea + nb*aeb + nc*aec + nd*aed + 0.5d0*(aea + aeb + aec + &
        aed) + a2*(n + 2) - ae*n) 
      s0 = 1.d0/e 
      s1 = 0.d0 
      s2 = 0.d0 
      m = ncd - k 
      do i = 1, m 
        s0 = s0*e/ecd 
        s1 = s1 + s0*(b(ncd-k,i)-b(ncd+k+1,i))/b(n,i) 
      end do 
      m1 = m + 1 
      m2 = ncd + k + 1 
      do i = m1, m2 
        s0 = s0*e/ecd 
        s2 = s2 + s0*b(m2,i)/b(n,i) 
      end do 
      s3 = exp(ae*n - acd*m2 - aab*(nab - k))/b(n,m2) 
      rsc = c*(s1 - s2 + s3) 
      return  
      end function rsc 


      subroutine scprm(ni, r066, r266, r466, r016, r244, r036, r236, r155, r355&
        , r125, r234, r246) 
!-----------------------------------------------
!   M o d u l e s 
!-----------------------------------------------
      USE vast_kind_param, ONLY:  double 
      USE mndod_C, only : iii, iiid 
      use parameters_C, only : zsn, zpn, zdn
!     *
!     ONE-CENTER TWO-ELECTRON INTEGRALS (SLATER-CONDON PARAMETERS) FOR S
!     *
!...Translated by Pacific-Sierra Research 77to90  4.4G  12:41:19  03/10/06  
!...Switches: -rl INDDO=2 INDIF=2 
!-----------------------------------------------
!   I n t e r f a c e   B l o c k s
!-----------------------------------------------
      use rsc_I 
      implicit none
!-----------------------------------------------
!   D u m m y   A r g u m e n t s
!-----------------------------------------------
      integer , intent(in) :: ni 
      real(double) , intent(out) :: r066 
      real(double) , intent(out) :: r266 
      real(double) , intent(out) :: r466 
      real(double) , intent(out) :: r016 
      real(double) , intent(out) :: r244 
      real(double) , intent(out) :: r036 
      real(double) , intent(out) :: r236 
      real(double) , intent(out) :: r155 
      real(double) , intent(out) :: r355 
      real(double) , intent(out) :: r125 
      real(double) , intent(out) :: r234 
      real(double) , intent(out) :: r246 
!-----------------------------------------------
!   L o c a l   V a r i a b l e s
!-----------------------------------------------
      integer :: ns, nd 
      real(double) :: es, ep, ed 
!-----------------------------------------------
      ns = iii(ni) 
      nd = iiid(ni) 
      es = zsn(ni) 
      ep = zpn(ni) 
      ed = zdn(ni) 
      r016 = rsc(0,ns,es,ns,es,nd,ed,nd,ed) 
      r036 = rsc(0,ns,ep,ns,ep,nd,ed,nd,ed) 
      r066 = rsc(0,nd,ed,nd,ed,nd,ed,nd,ed) 
      r155 = rsc(1,ns,ep,nd,ed,ns,ep,nd,ed) 
      r125 = rsc(1,ns,es,ns,ep,ns,ep,nd,ed) 
      r244 = rsc(2,ns,es,nd,ed,ns,es,nd,ed) 
      r236 = rsc(2,ns,ep,ns,ep,nd,ed,nd,ed) 
      r266 = rsc(2,nd,ed,nd,ed,nd,ed,nd,ed) 
      r234 = rsc(2,ns,ep,ns,ep,ns,es,nd,ed) 
      r246 = rsc(2,ns,es,nd,ed,nd,ed,nd,ed) 
      r355 = rsc(3,ns,ep,nd,ed,ns,ep,nd,ed) 
      r466 = rsc(4,nd,ed,nd,ed,nd,ed,nd,ed) 
      return  
      end subroutine scprm 


      subroutine spcore(ni, nj, r, core) 
!-----------------------------------------------
!   M o d u l e s 
!-----------------------------------------------
      USE vast_kind_param, ONLY:  double 
      use parameters_C, only : tore, po, ddp
      use funcon_C, only : ev
!...Translated by Pacific-Sierra Research 77to90  4.4G  12:41:19  03/10/06  
!...Switches: -rl INDDO=2 INDIF=2 
      implicit none
!-----------------------------------------------
!   D u m m y   A r g u m e n t s
!-----------------------------------------------
      integer , intent(in) :: ni 
      integer , intent(in) :: nj 
      real(double) , intent(in) :: r 
      real(double) , intent(out) :: core(10,2) 
!-----------------------------------------------
!   L o c a l   V a r i a b l e s
!-----------------------------------------------
      integer :: i 
      real(double), dimension(7) :: pxy 
      real(double), dimension(4) :: ai, aj 
      real(double), dimension(7) :: xi, xj 
      real(double) :: r2, aci, acj, ssi, ssj, ppj, da, qa, twoqa, adj, aqj, ppi&
        , db, qb, adi, aqi, twoqb 
!-----------------------------------------------
!     *
!     CALCULATE THE NUCLEAR ATTRACTION INTEGRALS IN LOCAL COORDINATES.
!     *
      data pxy/ 1.0d0, -0.5d0, -0.5d0, 0.5d0, 0.25d0, 0.25d0, 0.5d0/  
      core(:4,1) = 0.d0 
      core(:4,2) = 0.d0 
! *** INITIALIZATION.
      r2 = r*r 
      aci = po(9,ni) 
      acj = po(9,nj) 
! *** SS -CORE INTERACTION
      ssi = (aci + po(1,nj))**2 
      ssj = (acj + po(1,ni))**2 
      core(1,1) = -tore(nj)*ev/sqrt(r2 + ssj) 
      core(1,2) = -tore(ni)*ev/sqrt(r2 + ssi) 
      if (ni>=3 .or. nj>=3) then 
! *** NI -  HEAVY ATOM
        if (ni >= 3) then 
          ppj = (acj + po(7,ni))**2 
          da = ddp(2,ni) 
          qa = ddp(3,ni)/sqrt(2.d0) 
          twoqa = qa + qa 
          adj = (po(2,ni)+acj)**2 
          aqj = (po(3,ni)+acj)**2 
          xj(1) = r2 + ppj 
          xj(2) = r2 + aqj 
          xj(3) = (r + da)**2 + adj 
          xj(4) = (r - da)**2 + adj 
          xj(5) = (r - twoqa)**2 + aqj 
          xj(6) = (r + twoqa)**2 + aqj 
          xj(7) = r2 + twoqa*twoqa + aqj 
          do i = 1, 7 
            xj(i) = pxy(i)/sqrt(xj(i)) 
          end do 
          aj(2) = (xj(3)+xj(4))*ev 
          aj(3) = (xj(1)+xj(2)+xj(5)+xj(6))*ev 
          aj(4) = (xj(1)+xj(2)+xj(7))*ev 
          core(2,1) = -tore(nj)*aj(2) 
          core(3,1) = -tore(nj)*aj(3) 
          core(4,1) = -tore(nj)*aj(4) 
        endif 
! *** NJ- HEAVY ATOM
        if (nj >= 3) then 
          ppi = (aci + po(7,nj))**2 
          db = ddp(2,nj) 
          qb = ddp(3,nj)/sqrt(2.d0) 
          adi = (po(2,nj)+aci)**2 
          aqi = (po(3,nj)+aci)**2 
          twoqb = qb + qb 
          xi(1) = r2 + ppi 
          xi(2) = r2 + aqi 
          xi(3) = (r + db)**2 + adi 
          xi(4) = (r - db)**2 + adi 
          xi(5) = (r - twoqb)**2 + aqi 
          xi(6) = (r + twoqb)**2 + aqi 
          xi(7) = r2 + twoqb*twoqb + aqi 
          do i = 1, 7 
            xi(i) = pxy(i)/sqrt(xi(i)) 
          end do 
          ai(2) = -(xi(3)+xi(4))*ev 
          ai(3) = (xi(1)+xi(2)+xi(5)+xi(6))*ev 
          ai(4) = (xi(1)+xi(2)+xi(7))*ev 
          core(2,2) = -tore(ni)*ai(2) 
          core(3,2) = -tore(ni)*ai(3) 
          core(4,2) = -tore(ni)*ai(4) 
        endif 
      endif 
      return  
      end subroutine spcore 


      subroutine eiscor(r016, r066, r244, r266, r466, ni) 
!-----------------------------------------------
!   M o d u l e s 
!-----------------------------------------------
      USE vast_kind_param, ONLY:  double 
      use parameters_C, only : eisol
!***********************************************************************
!
!    EISCOR adds in the ONE-CENTER terms for the atomic energy of
!           those atoms that have partly filled "d" shells
!
!***********************************************************************
!...Translated by Pacific-Sierra Research 77to90  4.4G  12:41:19  03/10/06  
!...Switches: -rl INDDO=2 INDIF=2 
      implicit none
!-----------------------------------------------
!   D u m m y   A r g u m e n t s
!-----------------------------------------------
      integer , intent(in) :: ni 
      real(double) , intent(in) :: r016 
      real(double) , intent(in) :: r066 
      real(double) , intent(in) :: r244 
      real(double) , intent(in) :: r266 
      real(double) , intent(in) :: r466 
!-----------------------------------------------
!   L o c a l   V a r i a b l e s
!-----------------------------------------------
      integer , dimension(80) :: ir016, ir066, ir244, ir266, ir466 
      integer :: i 
!-----------------------------------------------
      data (ir016(i),ir066(i),ir244(i),ir266(i),ir466(i),i=1,20)/ 100*0/  
!
!                                Sc  Ti   V  Cr  Mn  Fe  Co  Ni  Cu
! Atomic orbital population   4s  2   2   2   1   2   2   2   2   1
! of gaseous atom             3d  1   2   3   5   5   6   7   8  10
!
! State term:                    2D  3F  4F  7S  6S  5D  4F  3F  2S
!
      data (ir016(i),i=21,29)/ 2, 4, 6, 5, 10, 12, 14, 16, 10/  
      data (ir066(i),i=21,29)/ 0, 1, 3, 10, 10, 15, 21, 28, 45/  
      data (ir244(i),i=21,29)/ 1, 2, 3, 5, 5, 6, 7, 8, 5/  
      data (ir266(i),i=21,29)/ 0, 8, 15, 35, 35, 35, 43, 50, 70/  
      data (ir466(i),i=21,29)/ 0, 1, 8, 35, 35, 35, 36, 43, 70/  
!
      data (ir016(i),ir066(i),ir244(i),ir266(i),ir466(i),i=30,38)/ 45*0/  
!
!                                 Y  Zr  Nb  Mo  Tc  Ru  Rh  Pd  Ag
! Atomic orbital population   5s  2   2   1   1   2   1   1   0   1
! of gaseous atom             4d  1   2   4   5   5   7   8  10  10
!
! State term:                    2D  3F  6D  7S  6D  5F  4F  1S  2S
!
      data (ir016(i),i=39,47)/ 2, 4, 4, 5, 10, 7, 8, 0, 10/  
      data (ir066(i),i=39,47)/ 0, 1, 6, 10, 10, 21, 28, 45, 45/  
      data (ir244(i),i=39,47)/ 1, 2, 4, 5, 5, 5, 5, 0, 5/  
      data (ir266(i),i=39,47)/ 0, 8, 21, 35, 35, 43, 50, 70, 70/  
      data (ir466(i),i=39,47)/ 0, 1, 21, 35, 35, 36, 43, 70, 70/  
!
      data (ir016(i),ir066(i),ir244(i),ir266(i),ir466(i),i=48,71)/ 120*0/  
!
!                                    Hf  Ta   W  Re  Os  Ir  Pt  Au Hg
! Atomic orbital population   6s      2   2   2   2   2   2   1   1  2
! of gaseous atom             5d      2   3   4   5   6   7   9  10  0
!
! State term:                        3F  4F  5D  6S  5D  4F  3D  2S 1S
!
      data (ir016(i),i=72,80)/ 4, 6, 8, 10, 12, 14, 9, 10, 0/  
      data (ir066(i),i=72,80)/ 1, 3, 6, 10, 15, 21, 36, 45, 0/  
      data (ir244(i),i=72,80)/ 2, 3, 4, 5, 6, 7, 5, 5, 0/  
      data (ir266(i),i=72,80)/ 8, 15, 21, 35, 35, 43, 56, 70, 0/  
      data (ir466(i),i=72,80)/ 1, 8, 21, 35, 35, 36, 56, 70, 0/  
!
!
!
!     R016:  <SS|DD>
!     R066:  <DD|DD> "0" term
!     R244:  <SD|SD>
!     R266:  <DD|DD> "2" term
!     R466:  <DD|DD> "4" term
!
      eisol(ni) = eisol(ni) + ir016(ni)*r016 + ir066(ni)*r066 - ir244(ni)*r244/&
        5 - ir266(ni)*r266/49 - ir466(ni)*r466/49 
      return  
      end subroutine eiscor 


      subroutine tx(ii, kk, rep, logv, v) 
!-----------------------------------------------
!   M o d u l e s 
!-----------------------------------------------
      USE vast_kind_param, ONLY:  double  
      use mndod_C, only : index, indx, ind2, sp, sd, pp, dp, dd
!     *
!     ROTATION OF TWO-ELECTRON TWO-CENTER INTEGRALS IN SPD BASIS
!     FIRST STEP
!     *
!...Translated by Pacific-Sierra Research 77to90  4.4G  12:41:19  03/10/06  
!...Switches: -rl INDDO=2 INDIF=2 
      implicit none
!-----------------------------------------------
!   D u m m y   A r g u m e n t s
!-----------------------------------------------
      integer , intent(in) :: ii 
      integer , intent(in) :: kk 
      real(double) , intent(in) :: rep(491) 
      real(double) , intent(out) :: v(45,45) 
      logical , intent(out) :: logv(45,45) 
!-----------------------------------------------
!   L o c a l   V a r i a b l e s
!-----------------------------------------------
      integer , dimension(45) :: met 
      integer :: limkl, k, i1, j1, ij, k1, l1, kl, nd, ll, mm, l 
      real(double) :: wrepp 
!-----------------------------------------------
      data met/ 1, 2, 3, 2, 3, 3, 2, 3, 3, 3, 4, 5, 5, 5, 6, 4, 5, 5, 5, 6, 6, &
        4, 5, 5, 5, 6, 6, 6, 4, 5, 5, 5, 6, 6, 6, 6, 4, 5, 5, 5, 5*6/  
!
      limkl = indx(kk,kk) 
      logv(:,:limkl) = .FALSE. 
      v(:,:limkl) = 0.D0 
!
      do i1 = 1, ii 
        do j1 = 1, i1 
          ij = index(i1,j1) 
!
          do k1 = 1, kk 
!
            do l1 = 1, k1 
              kl = index(k1,l1) 
              nd = ind2(ij,kl) 
              if (nd == 0) cycle  
!
              wrepp = rep(nd) 
              ll = indx(k1,l1) 
              mm = met(ll) 
!
              select case (mm)  
              case (1)  
                v(ij,1) = wrepp 
              case (2)  
                k = k1 - 1 
                v(ij,2) = v(ij,2) + sp(k,1)*wrepp 
                v(ij,4) = v(ij,4) + sp(k,2)*wrepp 
                v(ij,7) = v(ij,7) + sp(k,3)*wrepp 
              case (3)  
                k = k1 - 1 
                l = l1 - 1 
                v(ij,3) = v(ij,3) + pp(1,k,l)*wrepp 
                v(ij,6) = v(ij,6) + pp(2,k,l)*wrepp 
                v(ij,10) = v(ij,10) + pp(3,k,l)*wrepp 
                v(ij,5) = v(ij,5) + pp(4,k,l)*wrepp 
                v(ij,8) = v(ij,8) + pp(5,k,l)*wrepp 
                v(ij,9) = v(ij,9) + pp(6,k,l)*wrepp 
                cycle  
              case (4)  
                k = k1 - 4 
                v(ij,11) = v(ij,11) + sd(k,1)*wrepp 
                v(ij,16) = v(ij,16) + sd(k,2)*wrepp 
                v(ij,22) = v(ij,22) + sd(k,3)*wrepp 
                v(ij,29) = v(ij,29) + sd(k,4)*wrepp 
                v(ij,37) = v(ij,37) + sd(k,5)*wrepp 
              case (5)  
                k = k1 - 4 
                l = l1 - 1 
                v(ij,12) = v(ij,12) + dp(1,k,l)*wrepp 
                v(ij,13) = v(ij,13) + dp(2,k,l)*wrepp 
                v(ij,14) = v(ij,14) + dp(3,k,l)*wrepp 
                v(ij,17) = v(ij,17) + dp(4,k,l)*wrepp 
                v(ij,18) = v(ij,18) + dp(5,k,l)*wrepp 
                v(ij,19) = v(ij,19) + dp(6,k,l)*wrepp 
                v(ij,23) = v(ij,23) + dp(7,k,l)*wrepp 
                v(ij,24) = v(ij,24) + dp(8,k,l)*wrepp 
                v(ij,25) = v(ij,25) + dp(9,k,l)*wrepp 
                v(ij,30) = v(ij,30) + dp(10,k,l)*wrepp 
                v(ij,31) = v(ij,31) + dp(11,k,l)*wrepp 
                v(ij,32) = v(ij,32) + dp(12,k,l)*wrepp 
                v(ij,38) = v(ij,38) + dp(13,k,l)*wrepp 
                v(ij,39) = v(ij,39) + dp(14,k,l)*wrepp 
                v(ij,40) = v(ij,40) + dp(15,k,l)*wrepp 
              case (6)  
                k = k1 - 4 
                l = l1 - 4 
                v(ij,15) = v(ij,15) + dd(1,k,l)*wrepp 
                v(ij,21) = v(ij,21) + dd(2,k,l)*wrepp 
                v(ij,28) = v(ij,28) + dd(3,k,l)*wrepp 
                v(ij,36) = v(ij,36) + dd(4,k,l)*wrepp 
                v(ij,45) = v(ij,45) + dd(5,k,l)*wrepp 
                v(ij,20) = v(ij,20) + dd(6,k,l)*wrepp 
                v(ij,26) = v(ij,26) + dd(7,k,l)*wrepp 
                v(ij,27) = v(ij,27) + dd(8,k,l)*wrepp 
                v(ij,33) = v(ij,33) + dd(9,k,l)*wrepp 
                v(ij,34) = v(ij,34) + dd(10,k,l)*wrepp 
                v(ij,35) = v(ij,35) + dd(11,k,l)*wrepp 
                v(ij,41) = v(ij,41) + dd(12,k,l)*wrepp 
                v(ij,42) = v(ij,42) + dd(13,k,l)*wrepp 
                v(ij,43) = v(ij,43) + dd(14,k,l)*wrepp 
                v(ij,44) = v(ij,44) + dd(15,k,l)*wrepp 
!
              end select 
            end do 
          end do 
          where (v(ij,:limkl) /= 0.00D00)  
            logv(ij,:limkl) = .TRUE. 
          end where 
        end do 
      end do 
!
      return  
      end subroutine tx 


      subroutine w2mat(ip, jp, ww, w, lm6, limij, limkl) 
!-----------------------------------------------
!   M o d u l e s 
!-----------------------------------------------
      USE vast_kind_param, ONLY:  double 
!     *
!     STORE TWO-CENTER TWO-ELECTRON INTEGRALS IN A SQUARE MATRIX.
!     *
!...Translated by Pacific-Sierra Research 77to90  4.4G  12:41:19  03/10/06  
!...Switches: -rl INDDO=2 INDIF=2 
      implicit none
!-----------------------------------------------
!   D u m m y   A r g u m e n t s
!-----------------------------------------------
      integer , intent(in) :: ip 
      integer , intent(in) :: jp 
      integer , intent(in) :: lm6 
      integer , intent(in) :: limij 
      integer , intent(in) :: limkl 
      real(double) , intent(in) :: ww(limkl,limij) 
      real(double) , intent(out) :: w(lm6,lm6) 
!-----------------------------------------------
!   L o c a l   V a r i a b l e s
!-----------------------------------------------
      integer :: ipa, jpa
!-----------------------------------------------
      ipa = ip - 1 
      jpa = jp - 1 
      w(ipa+1:limij+ipa,jpa+1:limkl+jpa) = transpose(ww) 
      return  
      end subroutine w2mat 


      subroutine wstore(w) 
!-----------------------------------------------
!   M o d u l e s 
!-----------------------------------------------
      USE vast_kind_param, ONLY:  double 
      use molkst_C, only : numat, n2elec, lm6
      use permanent_arrays, only : nat, nfirst, nlast, nw
      use parameters_C, only : natorb, gss, gsp, gpp, gp2, hsp, hpp 
      use mndod_C, only : repd, intrep, intij, intkl
!     *
!     COMPLETE DEFINITION OF SQUARE MATRIX OF MNDO TWO-ELECTRON
!     INTEGRALS BY INCLUDING THE ONE-CENTER TERMS AND THE TERMS
!     WITH TRANSPOSED INDICES.
!     *
!     *
!***********************************************************************
!DECK MOPAC
!...Translated by Pacific-Sierra Research 77to90  4.4G  12:41:19  03/10/06  
!...Switches: -rl INDDO=2 INDIF=2 
      implicit none
!-----------------------------------------------
!   D u m m y   A r g u m e n t s
!-----------------------------------------------
      real(double) , intent(inout) :: w(n2elec,n2elec) 
!-----------------------------------------------
!   L o c a l   P a r a m e t e r s
!-----------------------------------------------
!-----------------------------------------------
!   L o c a l   V a r i a b l e s
!-----------------------------------------------
      integer :: ii, it, iw, ip, ipm, j, i, ni, ipx, ipy, ipz, ij0, ij, kl, int 
!-----------------------------------------------
! *** INITIALIZE ONE-CENTER INTEGRALS (LOWER TRIANGLE) TO 0.d0.
      do ii = 1, numat 
        if (nat(ii) <= 2) cycle  
        it = nlast(ii) - nfirst(ii) + 1 
        iw = it*(it + 1)/2 
        ip = nw(ii) 
        ipm = ip + iw - 1 
        do j = ip, ipm - 1 
          w(j+1:ipm,j) = 0.d0 
        end do 
      end do 
! *** INCLUDE NONZERO ONE-CENTER TERMS.
      do ii = 1, numat 
        ip = nw(ii) 
        ni = nat(ii) 
        w(ip,ip) = gss(ni) 
        if (natorb(ni) <= 2) cycle  
        ipx = ip + 2 
        ipy = ip + 5 
        ipz = ip + 9 
        w(ipx,ip) = gsp(ni) 
        w(ipy,ip) = gsp(ni) 
        w(ipz,ip) = gsp(ni) 
        w(ip,ipx) = gsp(ni) 
        w(ip,ipy) = gsp(ni) 
        w(ip,ipz) = gsp(ni) 
        w(ipx,ipx) = gpp(ni) 
        w(ipy,ipy) = gpp(ni) 
        w(ipz,ipz) = gpp(ni) 
        w(ipy,ipx) = gp2(ni) 
        w(ipz,ipx) = gp2(ni) 
        w(ipz,ipy) = gp2(ni) 
        w(ipx,ipy) = gp2(ni) 
        w(ipx,ipz) = gp2(ni) 
        w(ipy,ipz) = gp2(ni) 
        w(ip+1,ip+1) = hsp(ni) 
        w(ip+3,ip+3) = hsp(ni) 
        w(ip+6,ip+6) = hsp(ni) 
        w(ip+4,ip+4) = hpp(ni) 
        w(ip+7,ip+7) = hpp(ni) 
        w(ip+8,ip+8) = hpp(ni) 
        it = nlast(ii) - nfirst(ii) + 1 
        if (it <= 4) cycle  
        ij0 = ip - 1 
        do i = 1, 243 
          ij = intij(i) 
          kl = intkl(i) 
          int = intrep(i) 
          w(ij+ij0,kl+ij0) = repd(int,ni) 
        end do 
      end do 
! *** INCLUDE TERMS WITH TRANSPOSED INDICES.
      do i = 2, lm6 
        w(:i-1,i) = w(i,:i-1) 
      end do 
      return  
      end subroutine wstore 


      subroutine aijm(ni) 
!-----------------------------------------------
!   M o d u l e s 
!-----------------------------------------------
      USE vast_kind_param, ONLY:  double 
      USE mndod_C, only : aij,  iii, iiid, fx
      use parameters_C, only : zs, zp, zd, dorbs
!     *
!     AIJ-VALUES FOR EVALUATION OF TWO-CENTER TWO-ELECTRON INTEGRALS
!     AND OF HYBRID CONTRIBUTION TO DIPOLE MOMENT IN MNDO-D.
!     DEFINITION SEE EQUATION (7) OF TCA PAPER.
!     *
!     RESULTS ARE STORED IN ARRAY AIJ(6,5,107). CONVENTIONS:
!     FIRST  INDEX      1 SS, 2 SP, 3 PP, 4 SD, 5 PD, 6 DD.
!     SECOND INDEX      L+1 FROM DEFINITION OF MULTIPOLE.
!     THIRD  INDEX      ATOMIC NUMBER.
!     *
!...Translated by Pacific-Sierra Research 77to90  4.4G  12:41:19  03/10/06  
!...Switches: -rl INDDO=2 INDIF=2 
      implicit none
!-----------------------------------------------
!   D u m m y   A r g u m e n t s
!-----------------------------------------------
      integer , intent(in) :: ni 
!-----------------------------------------------
!   L o c a l   V a r i a b l e s
!-----------------------------------------------
      integer :: nsp, nd 
      real(double) :: z1, z2, z3, zz 
!-----------------------------------------------
!     *
!
!
      z1 = zs(ni) 
      z2 = zp(ni) 
      z3 = zd(ni) 
      nsp = iii(ni) 
      if (ni < 3) return  
      zz = z1*z2 
      if (zz < 0.01d0) return  
      aij(2,ni) = aijl(z1,z2,nsp,nsp,1) 
      aij(3,ni) = aijl(z2,z2,nsp,nsp,2) 
      if (dorbs(ni)) then 
        nd = iiid(ni) 
        aij(4,ni) = aijl(z1,z3,nsp,nd,2) 
        aij(5,ni) = aijl(z2,z3,nsp,nd,1) 
        aij(6,ni) = aijl(z3,z3,nd,nd,2) 
      endif 
      return  
      contains 


      real(double) function aijl (z1, z2, n1, n2, l) 
      REAL(double), intent(in) :: z1 
      REAL(double), intent(in) :: z2 
      integer, intent(in) :: n1 
      integer, intent(in) :: n2 
      integer, intent(in) :: l 
      aijl = fx(n1+n2+l+1)/sqrt(fx(2*n1+1)*fx(2*n2+1))*(2*z1/(z1 + z2))**n1*sqrt(2&
        *z1/(z1 + z2))*(2*z2/(z1 + z2))**n2*sqrt(2*z2/(z1 + z2))*2**l/(z1 + z2)&
        **l 
      return  
      end function aijl 
      end subroutine aijm 


 
    
!     ******************************************************************
     
      subroutine ccrep(ni, nj, r, enuclr) 
!-----------------------------------------------
!   M o d u l e s 
!-----------------------------------------------
      USE vast_kind_param, ONLY:  double 
      use mndod_C, only : iaf, ial, nalp, alpb, xfac  
      use parameters_C, only : alp, tore, guess1, guess2, guess3, po
      use funcon_C, only : a0, ev
      use molkst_C, only : method_am1, method_pm3
!...Translated by Pacific-Sierra Research 77to90  4.4G  12:41:19  03/10/06  
!...Switches: -rl INDDO=2 INDIF=2 
      implicit none
!-----------------------------------------------
!   D u m m y   A r g u m e n t s
!-----------------------------------------------
      integer , intent(in) :: ni 
      integer , intent(in) :: nj 
      real(double) , intent(inout) :: r 
      real(double) , intent(out) :: enuclr 
!-----------------------------------------------
!   L o c a l   V a r i a b l e s
!-----------------------------------------------
      integer :: nm, nl, ip, nt, ig 
      real(double) :: alpni, alpnj, gab, enuc, abond, fff, scale, eni, enj, ax 
!-----------------------------------------------
!     CONVERT TO ANGSTROM AND INITIALIZE VARIABLES.
      r = r*a0 
      alpni = alp(ni) 
      alpnj = alp(nj) 
!
!     CALCULATE REPULSIVE TERM.
      gab = ev/sqrt(r*r/(a0*a0) + (po(9,ni)+po(9,nj))**2) 
      enuc = tore(ni)*tore(nj)*gab 
!     USE BOND PARAMETERS IN MNDO/d (IF DEFINED).
!     ALPB(IP) IS USED AS ALPHA PARAMETER FOR THE ELEMENT WITH THE
!     ATOMIC NUMBER IAL(IP) IN CASE OF THE PAIR IAF(IP)-IAL(IP).
!     THE STANDARD ALPHA PARAMETER IS USED FOR THE OTHER ELEMENT.
!     CALCULATE SCALE FACTOR INCLUDING EXPONENTIAL TERMS.
      nm = 0 
      nl = 0 
      abond = 0.0D0 
      do ip = 1, nalp 
        if (ni==iaf(ip) .and. nj==ial(ip)) then 
          nm = nj 
          nl = ni 
          abond = alpb(ip) 
          exit  
        else if (nj==iaf(ip) .and. ni==ial(ip)) then 
          nm = ni 
          nl = nj 
          abond = alpb(ip) 
          exit  
        endif 
      end do 
!  ***
      if (nm*nl /= 0) then 
        if (method_am1) then 
!  ***      AM1/D
          fff = xfac(ip)*2.0D0 
          scale = 1.0D0 + fff*exp((-abond*r)) 
        else 
!  ***     MNDO/D
          scale = 1.0D0 + exp((-abond*r)) + exp((-alp(nl)*r)) 
          if (ni == nj) scale = 1.0D0 + 2.0D0*exp((-abond*r)) 
        endif 
        enuclr = enuc*scale 
        return  
      endif 
      eni = exp((-alpni*r)) 
      enj = exp((-alpnj*r)) 
      scale = eni + enj 
      nt = ni + nj 
      if (nt==8 .or. nt==9) then 
        if (ni==7 .or. ni==8) scale = scale + (r - 1.D0)*eni 
        if (nj==7 .or. nj==8) scale = scale + (r - 1.D0)*enj 
      endif 
      scale = abs(scale*enuc) 
   if (method_am1 .or. method_pm3) then 
        do ig = 1, 4 
          if (abs(guess1(ni,ig)) > 0.D0) then 
            ax = guess2(ni,ig)*(r - guess3(ni,ig))**2 
            if (ax <= 25.D0) scale = scale + tore(ni)*tore(nj)/r*guess1(ni,ig)*&
              exp((-ax)) 
          endif 
          if (abs(guess1(nj,ig)) <= 0.D0) cycle  
          ax = guess2(nj,ig)*(r - guess3(nj,ig))**2 
          if (ax > 25.D0) cycle  
          scale = scale + tore(ni)*tore(nj)/r*guess1(nj,ig)*exp((-ax)) 
        end do 
      endif 
      enuc = enuc + scale 
      enuclr = enuc 
      return  
      end subroutine ccrep 


      real(kind(0.0d0)) function charg (r, l1, l2, m, da, db, add) 
!-----------------------------------------------
!   M o d u l e s 
!-----------------------------------------------
      USE vast_kind_param, ONLY:  double 
!     *
!     INTERACTION BETWEEN 2.d0 POINT-CHARGE CONFIGURATIONS (MNDO-D).
!     *
!     R      DISTANCE IN ATOMIC UNITS.
!     L1,M   QUANTUM NUMBERS FOR MULTIPOLE OF CONFIGURATION 1.
!     L2,M   QUANTUM NUMBERS FOR MULTIPOLE OF CONFIGURATION 2.
!     DA     CHARGE SEPARATION OF CONFIGURATION 1.
!     DB     CHARGE SEPARATION OF CONFIGURATION 2.
!     ADD    ADDITIVE TERM
!     *
!...Translated by Pacific-Sierra Research 77to90  4.4G  12:41:19  03/10/06  
!...Switches: -rl INDDO=2 INDIF=2 
      implicit none
!-----------------------------------------------
!   D u m m y   A r g u m e n t s
!-----------------------------------------------
      integer , intent(in) :: l1 
      integer , intent(in) :: l2 
      integer , intent(in) :: m 
      real(double) , intent(in) :: r 
      real(double) , intent(in) :: da 
      real(double) , intent(in) :: db 
      real(double) , intent(in) :: add 
!-----------------------------------------------
!   L o c a l   V a r i a b l e s
!-----------------------------------------------
      real(double) :: dzdz, dxdx, qqzz, qzzq, dzqzz, qzzdz, zzzz, xyxy, ab, &
        dxqxz, aa, qxzdx, qxzqxz 
!-----------------------------------------------
!
      charg = 0.0D00 
!     Q - Q.
      if (l1==0 .and. l2==0) then 
        charg = 1.D00/sqrt(r**2 + add) 
!     Z - Q.
      else if (l1==1 .and. l2==0) then 
        charg = (-1.D00/sqrt((r + da)**2 + add)) + 1.D00/sqrt((r - da)**2 + add&
          ) 
        charg = charg/2.0D00 
!     Q - Z.
      else if (l1==0 .and. l2==1) then 
        charg = 1.D00/sqrt((r + db)**2 + add) - 1.D00/sqrt((r - db)**2 + add) 
        charg = charg/2.D00 
!     Z - Z.
      else if (l1==1 .and. l2==1 .and. m==0) then 
        dzdz = 1.D00/sqrt((r + da - db)**2 + add) + 1.D00/sqrt((r - da + db)**2&
           + add) - 1.D00/sqrt((r - da - db)**2 + add) - 1.D00/sqrt((r + da + &
          db)**2 + add) 
        charg = dzdz/4.D00 
!     X - X
      else if (l1==1 .and. l2==1 .and. m==1) then 
        dxdx = 2.D00/sqrt(r**2 + (da - db)**2 + add) - 2.D00/sqrt(r**2 + (da + &
          db)**2 + add) 
        charg = dxdx*0.25D00 
!     Q - ZZ
      else if (l1==0 .and. l2==2) then 
        qqzz = 1.D00/sqrt((r - db)**2 + add) - 2.D00/sqrt(r**2 + db**2 + add)&
           + 1.D00/sqrt((r + db)**2 + add) 
        charg = qqzz/4.D00 
!     ZZ -Q
      else if (l1==2 .and. l2==0) then 
        qzzq = 1.D00/sqrt((r - da)**2 + add) - 2.D00/sqrt(r**2 + da**2 + add)&
           + 1.D00/sqrt((r + da)**2 + add) 
        charg = qzzq/4.D00 
!     Z - ZZ
      else if (l1==1 .and. l2==2 .and. m==0) then 
        dzqzz = 1.D00/sqrt((r - da - db)**2 + add) - 2.D00/sqrt((r - da)**2 + &
          db**2 + add) + 1.D00/sqrt((r + db - da)**2 + add) - 1.D00/sqrt((r - &
          db + da)**2 + add) + 2.D00/sqrt((r + da)**2 + db**2 + add) - 1.D00/&
          sqrt((r + da + db)**2 + add) 
        charg = dzqzz/8.D00 
!     ZZ - Z
      else if (l1==2 .and. l2==1 .and. m==0) then 
        qzzdz = (-1.D00/sqrt((r - da - db)**2 + add)) + 2.D00/sqrt((r - db)**2&
           + da**2 + add) - 1.D00/sqrt((r + da - db)**2 + add) + 1.D00/sqrt((r&
           - da + db)**2 + add) - 2.D00/sqrt((r + db)**2 + da**2 + add) + 1.D00&
          /sqrt((r + da + db)**2 + add) 
        charg = qzzdz/8.D00 
!     ZZ - ZZ
      else if (l1==2 .and. l2==2 .and. m==0) then 
        zzzz = 1.D00/sqrt((r - da - db)**2 + add) + 1.D00/sqrt((r + da + db)**2&
           + add) + 1.D00/sqrt((r - da + db)**2 + add) + 1.D00/sqrt((r + da - &
          db)**2 + add) - 2.D00/sqrt((r - da)**2 + db**2 + add) - 2.D00/sqrt((r&
           - db)**2 + da**2 + add) - 2.D00/sqrt((r + da)**2 + db**2 + add) - &
          2.D00/sqrt((r + db)**2 + da**2 + add) + 2.D00/sqrt(r**2 + (da - db)**&
          2 + add) + 2.D00/sqrt(r**2 + (da + db)**2 + add) 
        xyxy = 4.D00/sqrt(r**2 + (da - db)**2 + add) + 4.D00/sqrt(r**2 + (da + &
          db)**2 + add) - 8.D00/sqrt(r**2 + da**2 + db**2 + add) 
        charg = zzzz/16.D00 - xyxy/64.D00 
!     X - ZX
      else if (l1==1 .and. l2==2 .and. m==1) then 
        ab = db/sqrt(2.D0) 
        dxqxz = (-2.D00/sqrt((r - ab)**2 + (da - ab)**2 + add)) + 2.D00/sqrt((r&
           + ab)**2 + (da - ab)**2 + add) + 2.D00/sqrt((r - ab)**2 + (da + ab)&
          **2 + add) - 2.D00/sqrt((r + ab)**2 + (da + ab)**2 + add) 
        charg = dxqxz/8.D00 
!     ZX - X
      else if (l1==2 .and. l2==1 .and. m==1) then 
        aa = da/sqrt(2.D0) 
        qxzdx = (-2.D00/sqrt((r + aa)**2 + (aa - db)**2 + add)) + 2.D00/sqrt((r&
           - aa)**2 + (aa - db)**2 + add) + 2.D00/sqrt((r + aa)**2 + (aa + db)&
          **2 + add) - 2.D00/sqrt((r - aa)**2 + (aa + db)**2 + add) 
        charg = qxzdx/8.D00 
!     ZX - ZX
      else if (l1==2 .and. l2==2 .and. m==1) then 
        aa = da/sqrt(2.D0) 
        ab = db/sqrt(2.D0) 
        qxzqxz = 2.D00/sqrt((r + aa - ab)**2 + (aa - ab)**2 + add) - 2.D00/&
          sqrt((r + aa + ab)**2 + (aa - ab)**2 + add) - 2.D00/sqrt((r - aa - ab&
          )**2 + (aa - ab)**2 + add) + 2.D00/sqrt((r - aa + ab)**2 + (aa - ab)&
          **2 + add) - 2.D00/sqrt((r + aa - ab)**2 + (aa + ab)**2 + add) + &
          2.D00/sqrt((r + aa + ab)**2 + (aa + ab)**2 + add) + 2.D00/sqrt((r - &
          aa - ab)**2 + (aa + ab)**2 + add) - 2.D00/sqrt((r - aa + ab)**2 + (aa&
           + ab)**2 + add) 
        charg = qxzqxz/16.D00 
!     XX - XX
      else if (l1==2 .and. l2==2 .and. m==2) then 
        xyxy = 4.D00/sqrt(r**2 + (da - db)**2 + add) + 4.D00/sqrt(r**2 + (da + &
          db)**2 + add) - 8.D00/sqrt(r**2 + da**2 + db**2 + add) 
        charg = xyxy/16.D00 
      endif 
      return  
      end function charg 


      subroutine ddpo(ni) 
!-----------------------------------------------
!   M o d u l e s 
!-----------------------------------------------
      USE vast_kind_param, ONLY:  double 
      use parameters_C, only : dorbs, gss, hsp, hpp, ddp, po
      use mndod_C, only :  aij, repd
!     *
!     CALCULATION OF CHARGE SEPARATIONS AND ADDITIVE TERMS USED
!     TO COMPUTE THE TWO-CENTER TWO-ELECTRON INTEGRALS IN MNDO/D.
!     *
!     CHARGE SEPARATIONS DD(6,107) FROM ARRAY AIJ COMPUTED IN AIJM.
!     ADDITIVE TERMS     PO(9,107) FROM FUNCTION POIJ.
!     SECOND INDEX OF DD AND PO    SS 1, SP 2,PP 8, PP 3, SD 4, PD 5, DD
!     SEE EQUATIONS (12)-(16) OF TCA PAPER FOR DD.
!     SEE EQUATIONS (19)-(26) OF TCA PAPER FOR PO.
!     SPECIAL CONVENTION FOR ATOMIC CORE: ADDITIVE TERM PO(9,NI)
!     USED IN THE EVALUATION OF THE CORE-ELECTRON ATTRACTIONS AND
!     CORE-CORE REPULSIONS.
!     *
!...Translated by Pacific-Sierra Research 77to90  4.4G  12:41:19  03/10/06  
!...Switches: -rl INDDO=2 INDIF=2 
!-----------------------------------------------
!   I n t e r f a c e   B l o c k s
!-----------------------------------------------
      use poij_I 
      implicit none
!-----------------------------------------------
!   D u m m y   A r g u m e n t s
!-----------------------------------------------
      integer , intent(in) :: ni 
!-----------------------------------------------
!   L o c a l   V a r i a b l e s
!-----------------------------------------------
      real(double) :: fg, d, da 
!-----------------------------------------------
! *** ADDITIVE TERM FOR SS.
      fg = gss(ni) 
      po(1,ni) = poij(0,1.d0,fg) 
      if (ni >= 3) then 
! *** OTHER TERMS FOR SP BASIS.
!     SP
        d = aij(2,ni)/sqrt(12.0D0) 
        fg = hsp(ni) 
        ddp(2,ni) = d 
        po(2,ni) = poij(1,d,fg) 
!     PP
        po(7,ni) = po(1,ni) 
        d = sqrt(aij(3,ni)*0.1D0) 
        fg = hpp(ni) 
        ddp(3,ni) = d 
        po(3,ni) = poij(2,d,fg) 
! *** TERMS INVOLVING D ORBITALS.
        if (dorbs(ni)) then 
!     SD
          da = sqrt(1.d0/60.0D0) 
          d = sqrt(aij(4,ni)*da) 
          fg = repd(19,ni) 
          ddp(4,ni) = d 
          po(4,ni) = poij(2,d,fg) 
!     PD
          d = aij(5,ni)/sqrt(20.0D0) 
          fg = repd(23,ni) - 1.8D0*repd(35,ni) 
          ddp(5,ni) = d 
          po(5,ni) = poij(1,d,fg) 
!     DD
          fg = 0.2D0*(repd(29,ni)+2.d0*repd(30,ni)+2.d0*repd(31,ni)) 
          po(8,ni) = poij(0,1.d0,fg) 
          d = sqrt(aij(6,ni)/14.0D0) 
          fg = repd(44,ni) - (20.0D0/35.0D0)*repd(52,ni) 
          ddp(6,ni) = d 
          po(6,ni) = poij(2,d,fg) 
        endif 
      endif 
      return  
      end subroutine ddpo 


      subroutine dfockd(f, w, nati) 
!-----------------------------------------------
!   M o d u l e s 
!-----------------------------------------------
      USE vast_kind_param, ONLY:  double 
      use molkst_C, only : norbs, numat, lm6, mpack
      use permanent_arrays, only : nfirst, nlast, p, pa, nw
!***********************************************************************
!DECK MOPAC
!...Translated by Pacific-Sierra Research 77to90  4.4G  12:41:19  03/10/06  
!...Switches: -rl INDDO=2 INDIF=2 
      implicit none
!-----------------------------------------------
!   D u m m y   A r g u m e n t s
!-----------------------------------------------
      integer , intent(in) :: nati
      real(double) , intent(inout) :: f(mpack)  
      real(double) , intent(in) :: w(lm6,45) 
!-----------------------------------------------
!   L o c a l   pa a r a m e t e r s
!-----------------------------------------------
!-----------------------------------------------
!   L o c a l   V a r i a b l e s
!-----------------------------------------------
      integer , dimension(:), allocatable :: ifact 
      integer :: i, j1, nwii, ii, jj, ia, ib, ja, jb, ijw, ka, j, kb, ij, klw, &
        k, kc, ik, jk, l, il, jl, kl 
      real(double) :: aa, bb, a 
!-----------------------------------------------
!***********************************************************************
!
!     DFOCKD ADDS THE 2-ELECTRON 2-CENTER REPULSION CONTRIBUTION TO
!     THE FOCK MATRIX DERIVATIVE WITHIN THE NDDO FORMALISMS.
!  INPUT
!     F    : 1-ELECTRON CONTRIBUTIONS DERIVATIVES.
!     p : TOTAL DENSITY MATRIX.
!     pa    : ALPHA OR BETA DENSITY MATRIX. = 0.5 * p
!     W    : NON VANISHING TWO-ELECTRON INTEGRAL DERIVATIVES
!            (ORDERED AS DEFINED IN DHCORE).
!     NATI : # OF THE ATOM SUPPORTING THE VARYING CARTESIAN COORDINATE.
!  OUTPUT
!     F    : FOCK MATRIX DERIVATIVE WITH RESPECT TO THE CART. COORD.
!
!***********************************************************************
!
!   SET UP ARRAY OF (I*(I-1))/2
!
      allocate(ifact(norbs))
      do i = 1, norbs 
        ifact(i) = (i*(i - 1))/2 
      end do 
      do j1 = 1, numat 
        if (nati == j1) cycle  
        nwii = nw(j1) 
        ii = j1 
        jj = nati 
        ia = nfirst(ii) 
        ib = nlast(ii) 
        ja = nfirst(jj) 
        jb = nlast(jj) 
        ijw = nwii - 1 
        do i = ia, ib 
          ka = ifact(i) 
          aa = 2.0D00 
          do j = ia, i 
            if (i == j) aa = 1.0D00 
            ijw = ijw + 1 
            kb = ifact(j) 
            ij = ka + j 
            klw = 0 
            if (ia < ja) then 
              do k = ja, jb 
                kc = ifact(k) 
                ik = ka + k 
                jk = kb + k 
                bb = 2.0D00 
                do l = ja, k 
                  if (k == l) bb = 1.0D00 
                  il = ka + l 
                  jl = kb + l 
                  kl = kc + l 
                  ik = (k*(k - 1))/2 + i 
                  il = (l*(l - 1))/2 + i 
                  jk = (k*(k - 1))/2 + j 
                  jl = (l*(l - 1))/2 + j 
                  klw = klw + 1 
                  a = w(ijw,klw) 
                  f(ij) = f(ij) + bb*a*p(kl) 
                  f(kl) = f(kl) + aa*a*p(ij) 
                  a = a*aa*bb*0.25D0 
                  f(ik) = f(ik) - a*pa(jl) 
                  f(il) = f(il) - a*pa(jk) 
                  f(jk) = f(jk) - a*pa(il) 
                  f(jl) = f(jl) - a*pa(ik) 
                end do 
              end do 
            else 
              do k = ja, jb 
                kc = ifact(k) 
                ik = ka + k 
                jk = kb + k 
                bb = 2.0D00 
                do l = ja, k 
                  if (k == l) bb = 1.0D00 
                  il = ka + l 
                  jl = kb + l 
                  kl = kc + l 
                  klw = klw + 1 
                  a = w(ijw,klw) 
                  f(ij) = f(ij) + bb*a*p(kl) 
                  f(kl) = f(kl) + aa*a*p(ij) 
                  a = a*aa*bb*0.25D0 
                  f(ik) = f(ik) - a*pa(jl) 
                  f(il) = f(il) - a*pa(jk) 
                  f(jk) = f(jk) - a*pa(il) 
                  f(jl) = f(jl) - a*pa(ik) 
                end do 
              end do 
            endif 
          end do 
        end do 
      end do 
      return  
      end subroutine dfockd 


      subroutine dijkld(c, n, nati, w, wd, cij, wcij, ckl, xy) 
!-----------------------------------------------
!   M o d u l e s 
!-----------------------------------------------
      USE vast_kind_param, ONLY:  double 
      USE meci_C, only : nmos
      use molkst_C, only : norbs, numat, lm6, method_dorbs
      use permanent_arrays, only : nfirst, nlast, nw
!***********************************************************************
!DECK MOPAC
!...Translated by Pacific-Sierra Research 77to90  4.4G  12:41:19  03/10/06  
!...Switches: -rl INDDO=2 INDIF=2 
!-----------------------------------------------
!   I n t e r f a c e   B l o c k s
!-----------------------------------------------
      use formxd_I 
      use formxy_I 
      implicit none
!-----------------------------------------------
!   G l o b a l   P a r a m e t e r s
!-----------------------------------------------

!-----------------------------------------------
!   D u m m y   A r g u m e n t s
!-----------------------------------------------
      integer , intent(in) :: n 
      integer , intent(in) :: nati 
      real(double) , intent(in) :: c(n,*) 
      real(double)  :: w(*) 
      real(double)  :: wd(lm6,45) 
      real(double)  :: cij(10*norbs) 
      real(double)  :: wcij(10*norbs) 
      real(double) , intent(inout) :: ckl(10*norbs) 
      real(double) , intent(out) :: xy(nmos,nmos,nmos,nmos) 
!-----------------------------------------------
!   L o c a l   P a r a m e t e r s
!-----------------------------------------------
!-----------------------------------------------
!   L o c a l   V a r i a b l e s
!-----------------------------------------------
      integer , dimension(0:8) :: nb 
      integer :: na, i, j, ipq, ii, ip, i77, kr, js, nbj, nbi, nwii, ia, ib&
        , jb, ja, k, ll, l 
      real(double) :: sum
      save nb 
!-----------------------------------------------
!***********************************************************************
!
!   DIJKL1 IS SIMILAR TO IJKL.  THE MAIN DIFFERENCES ARE THAT
!   THE ARRAY W CONTAINS THE 2.d0 ELECTRON INTEGRALS BETWEEN
!   1.d0 ATOM (NATI) AND ALL THE OTHER ATOMS IN THE SYSTEM.
!
!           ON EXIT
!
!   THE ARRAY XY IS FILLED WITH THE DIFFERENTIALS OF THE
!   TWO-ELECTRON INTEGRALS OVER ACTIVE-SPACE M.O.S W.R.T. MOTION
!   OF THE ATOM NATI.
!***********************************************************************
      data nb/ 1, 0, 0, 10, 0, 0, 0, 0, 45/ 
      na = nmos 
      do i = 1, na 
        do j = 1, i 
          ipq = 0 
          do ii = 1, numat 
            if (ii == nati) cycle  
            do ip = nfirst(ii), nlast(ii) 
              if (ip - nfirst(ii) + 1 > 0) then 
                cij(ipq+1:ip-nfirst(ii)+1+ipq) = c(ip,i)*c(nfirst(ii):ip,j) + c&
                  (ip,j)*c(nfirst(ii):ip,i) 
                ipq = ip - nfirst(ii) + 1 + ipq 
              endif 
            end do 
          end do 
          i77 = ipq + 1 
          do ip = nfirst(nati), nlast(nati) 
            if (ip - nfirst(nati) + 1 > 0) then 
              cij(ipq+1:ip-nfirst(nati)+1+ipq) = c(ip,i)*c(nfirst(nati):ip,j)&
                 + c(ip,j)*c(nfirst(nati):ip,i) 
              ipq = ip - nfirst(nati) + 1 + ipq 
            endif 
          end do 
          wcij(:ipq) = 0.D0 
          kr = 1 
          js = 1 
          nbj = nlast(nati) - nfirst(nati) 
          if (nbj >= 0) then 
            nbj = nb(nbj) 
            do ii = 1, numat 
              if (ii == nati) cycle  
              nbi = nlast(ii) - nfirst(ii) 
              if (nbi < 0) cycle  
              nbi = nb(nbi) 
              if (method_dorbs) then 
                nwii = nw(ii) - 1 
                ia = nfirst(nati) 
                ib = nlast(nati) 
                jb = nlast(ii) 
                ja = nfirst(ii) 
                call formxd (wd, 0, nwii, wcij(i77), wcij(js), cij(i77), ib - &
                  ia + 1, cij(js), jb - ja + 1) 
              else 
                call formxy (w(kr), kr, wcij(i77), wcij(js), cij(i77), nbj, cij&
                  (js), nbi) 
              endif 
              js = js + nbi 
            end do 
          endif 
          do k = 1, i 
            if (k == i) then 
              ll = j 
            else 
              ll = k 
            endif 
            do l = 1, ll 
              ipq = 0 
              do ii = 1, numat 
                if (ii == nati) cycle  
                do ip = nfirst(ii), nlast(ii) 
                  if (ip - nfirst(ii) + 1 > 0) then 
                    ckl(ipq+1:ip-nfirst(ii)+1+ipq) = c(ip,k)*c(nfirst(ii):ip,l)&
                       + c(ip,l)*c(nfirst(ii):ip,k) 
                    ipq = ip - nfirst(ii) + 1 + ipq 
                  endif 
                end do 
              end do 
              do ip = nfirst(nati), nlast(nati) 
                if (ip - nfirst(nati) + 1 > 0) then 
                  ckl(ipq+1:ip-nfirst(nati)+1+ipq) = c(ip,k)*c(nfirst(nati):ip,&
                    l) + c(ip,l)*c(nfirst(nati):ip,k) 
                  ipq = ip - nfirst(nati) + 1 + ipq 
                endif 
              end do 
              sum = 0.D0 
              do ii = 1, ipq 
                sum = sum + ckl(ii)*wcij(ii) 
              end do 
              xy(i,j,k,l) = sum 
              xy(i,j,l,k) = sum 
              xy(j,i,k,l) = sum 
              xy(j,i,l,k) = sum 
              xy(k,l,i,j) = sum 
              xy(k,l,j,i) = sum 
              xy(l,k,i,j) = sum 
              xy(l,k,j,i) = sum 
            end do 
          end do 
        end do 
      end do 
      return  
      end subroutine dijkld 


      subroutine elenuc(ia, ib, ja, jb, h) 
!-----------------------------------------------
!   M o d u l e s 
!-----------------------------------------------
      USE vast_kind_param, ONLY:  double 
      use molkst_C, only : mpack
      use mndod_C, only : sp, sd, pp, dp, dd, cored, inddd, inddp, indpp
!***********************************************************************
!
!   ELENUC - Nuclear stabilization terms added to 1.d0-electron matrix
!
!***********************************************************************
!...Translated by Pacific-Sierra Research 77to90  4.4G  12:41:19  03/10/06  
!...Switches: -rl INDDO=2 INDIF=2 
      implicit none
!-----------------------------------------------
!   D u m m y   A r g u m e n t s
!-----------------------------------------------
      integer , intent(in) :: ia 
      integer , intent(in) :: ib 
      integer , intent(in) :: ja 
      integer , intent(in) :: jb 
      real(double) , intent(inout) :: h(mpack)  
!-----------------------------------------------
!   L o c a l   V a r i a b l e s
!-----------------------------------------------
      integer :: k, l, n, i, ind1, j, ind2, m, ipp, idp, idd 
!-----------------------------------------------
!
!
!     (SS/)=1,   (SO/)=2,   (OO/)=3,   (PP/)=4
!
!     (D S/)=5,  (D P /)=6, (D D /)=7, (D+P+/)=8, (D+D+/)=9, (D#D#/)=10
      k = ia 
      l = ib 
      n = 1 
!
   10 continue 
      do i = k, l 
        ind1 = i - k 
        if (ind1 == 0) then 
          do j = k, i 
            ind2 = j - k 
            m = (i*(i - 1))/2 + j 
            if (ind2 == 0) then 
! -- (SS/)
              h(m) = h(m) + cored(1,n) 
! -- (SD/)
            else 
              if (ind2 < 4) then 
! -- (PP/)
                ipp = indpp(ind1,ind2) 
                h(m) = h(m) + cored(3,n)*pp(ipp,1,1) + cored(4,n)*(pp(ipp,2,2)+pp&
                  (ipp,3,3)) 
! -- (PD/)
              else 
! -- (DD/)
                idd = inddd(ind1-3,ind2-3) 
                h(m) = h(m) + cored(7,n)*dd(idd,1,1) + cored(9,n)*(dd(idd,2,2)+dd&
                  (idd,3,3)) + cored(10,n)*(dd(idd,4,4)+dd(idd,5,5)) 
              endif 
            endif 
!
          end do 
        else 
          if (ind1 < 4) then 
            do j = k, i 
              ind2 = j - k 
              m = (i*(i - 1))/2 + j 
              if (ind2 == 0) then 
! -- (SP/)
                h(m) = h(m) + sp(1,ind1)*cored(2,n) 
! -- (SD/)
              else 
                if (ind2 < 4) then 
! -- (PP/)
                  ipp = indpp(ind1,ind2) 
                  h(m) = h(m) + cored(3,n)*pp(ipp,1,1) + cored(4,n)*(pp(ipp,2,2)+&
                    pp(ipp,3,3)) 
! -- (PD/)
                else 
! -- (DD/)
                  idd = inddd(ind1-3,ind2-3) 
                  h(m) = h(m) + cored(7,n)*dd(idd,1,1) + cored(9,n)*(dd(idd,2,2)+&
                    dd(idd,3,3)) + cored(10,n)*(dd(idd,4,4)+dd(idd,5,5)) 
                endif 
              endif 
!
            end do 
          else 
            do j = k, i 
              ind2 = j - k 
              m = (i*(i - 1))/2 + j 
              if (ind2 == 0) then 
! -- (SD/)
                h(m) = h(m) + sd(1,ind1-3)*cored(5,n) 
              else 
                if (ind2 < 4) then 
! -- (PD/)
                  idp = inddp(ind1-3,ind2) 
                  h(m) = h(m) + cored(6,n)*dp(idp,1,1) + cored(8,n)*(dp(idp,2,2)+&
                    dp(idp,3,3)) 
                else 
! -- (DD/)
                  idd = inddd(ind1-3,ind2-3) 
                  h(m) = h(m) + cored(7,n)*dd(idd,1,1) + cored(9,n)*(dd(idd,2,2)+&
                    dd(idd,3,3)) + cored(10,n)*(dd(idd,4,4)+dd(idd,5,5)) 
                endif 
              endif 
!
            end do 
          endif 
        endif 
      end do 
!
      if (n == 2) go to 30 
!
      k = ja 
      l = jb 
      n = 2 
!
      go to 10 
   30 continue 
      return  
      end subroutine elenuc 


      subroutine fbx 
!-----------------------------------------------
!   M o d u l e s 
!-----------------------------------------------
      use mndod_C, only : fx, b
!     *
!     DEFINE FACTORIALS AND BINOMIAL COEFFICIENTS.
!     fx(30)     FACTORIALS.
!     B(30,30)      BINOMIAL COEFFICIENTS.
!     *
!...Translated by Pacific-Sierra Research 77to90  4.4G  12:41:19  03/10/06  
!...Switches: -rl INDDO=2 INDIF=2 
      implicit none 
!-----------------------------------------------
!   L o c a l   V a r i a b l e s
!-----------------------------------------------
      integer :: i
!-----------------------------------------------
      fx(1) = 1.D0 
      do i = 2, 30 
        fx(i) = fx(i-1)*dble(i - 1) 
      end do 
      b(:,1) = 1.D0 
      b(:,2:30) = 0.D0 
      do i = 2, 30 
        b(i,2:i) = b(i-1,:i-1) + b(i-1,2:i) 
      end do 
      return  
      end subroutine fbx 
        subroutine fockd1(f, ptot, pa, w) 
!-----------------------------------------------
!   M o d u l e s 
!-----------------------------------------------
      USE vast_kind_param, ONLY:  double 
      USE molkst_C, only : numat, lm6
      use permanent_arrays, only : nfirst, nlast, nw
!***********************************************************************
!DECK MOPAC
!...Translated by Pacific-Sierra Research 77to90  4.4G  12:41:19  03/10/06  
!...Switches: -rl INDDO=2 INDIF=2 
      implicit none
!-----------------------------------------------
!   G l o b a l   P a r a m e t e r s
!-----------------------------------------------
!-----------------------------------------------
!   D u m m y   A r g u m e n t s
!-----------------------------------------------
      real(double) , intent(inout) :: f(*) 
      real(double) , intent(in) :: ptot(*) 
      real(double) , intent(in) :: pa(*) 
      real(double) , intent(in) :: w(lm6,lm6) 
!-----------------------------------------------
!   L o c a l   P a r a m e t e r s
!-----------------------------------------------
!-----------------------------------------------
!   L o c a l   V a r i a b l e s
!-----------------------------------------------
      integer :: ii, nwii, ia, ib, i, iw, j, jw, ij, ijw, k, kw, l, lw, ip, jp&
        , ijp, im, jm, klw, ikw, jlw 
      real(double) :: sum 
!-----------------------------------------------
! *********************************************************************
!
! *** COMPUTE THE REMAINING CONTRIBUTIONS TO THE ONE-CENTER ELEMENTS.
!
! *********************************************************************
      do ii = 1, numat 
        nwii = nw(ii) - 1 
        ia = nfirst(ii) 
        ib = nlast(ii) 
!
!   ONE-CENTER coulomb and exchange terms for atom II.
!
!  F(i,j)=F(i,j)+sum(k,l)((PA(k,l)+PB(k,l))*<i,j|k,l>
!                        -(PA(k,l)        )*<i,k|j,l>), k,l on atom II.
!
        do i = ia, ib 
          iw = i - ia + 1 
          do j = ia, i 
            jw = j - ia + 1 
!
!    Address in `F'
!
            ij = (i*(i - 1))/2 + j 
!
!    `J' Address IJ in W
!
            ijw = nwii + (iw*(iw - 1))/2 + jw 
            sum = 0.D0 
            do k = ia, ib 
              kw = k - ia + 1 
              do l = ia, ib 
                lw = l - ia + 1 
                ip = max(k,l) 
                jp = min(k,l) 
!
!    Address in `P'
!
                ijp = (ip*(ip - 1))/2 + jp 
!
!    `J' Address KL in W
!
                im = max(kw,lw) 
                jm = min(kw,lw) 
                klw = nwii + (im*(im - 1))/2 + jm 
!
!    `K' Address IK in W
!
                im = max(kw,jw) 
                jm = min(kw,jw) 
                ikw = nwii + (im*(im - 1))/2 + jm 
!
!    `K' Address JL in W
!
                im = max(lw,iw) 
                jm = min(lw,iw) 
                jlw = nwii + (im*(im - 1))/2 + jm 
!
!   The term itself
!
                sum = sum + ptot(ijp)*w(ijw,klw) - pa(ijp)*w(ikw,jlw) 
              end do 
            end do 
            f(ij) = f(ij) + sum 
          end do 
        end do 
      end do 
      return  
      end subroutine fockd1 


      subroutine fockd2(f, ptot, p, w, lm6, wj, wk, numat, nfirst, nlast, nw) 
!-----------------------------------------------
!   M o d u l e s 
!-----------------------------------------------
      USE vast_kind_param, ONLY:  double 
      USE cosmo_C, only : useps 
      use molkst_C, only : norbs
!***********************************************************************
!DECK MOPAC
!...Translated by Pacific-Sierra Research 77to90  4.4G  12:41:19  03/10/06  
!...Switches: -rl INDDO=2 INDIF=2 
!-----------------------------------------------
!   I n t e r f a c e   B l o c k s
!-----------------------------------------------
      use addfck_I 
      implicit none
!-----------------------------------------------
!   D u m m y   A r g u m e n t s
!-----------------------------------------------
      integer , intent(in) :: lm6 
      integer  :: numat 
      integer  :: nfirst(numat) 
      integer  :: nlast(numat) 
      integer , intent(in) :: nw(numat) 
      real(double)  :: f(*) 
      real(double) , intent(in) :: ptot(*) 
      real(double)  :: p(*) 
      real(double) , intent(in) :: w(lm6,lm6) 
      real(double) , intent(in) :: wj(*) 
      real(double) , intent(in) :: wk(*) 
!-----------------------------------------------
!   L o c a l   P a r a m e t e r s
!-----------------------------------------------
!-----------------------------------------------
!   L o c a l   V a r i a b l e s
!-----------------------------------------------
      integer , dimension(norbs) :: ifact 
      integer :: i, ii, ia, ib, jj, ja, jb, ijw, ka, j, kb, ij, klw, k, kc, ik&
        , jk, l, il, jl, kl 
      real(double) :: a, aa, bb 
!-----------------------------------------------
!***********************************************************************
!
! FOCKD2 FORMS THE TWO-ELECTRON TWO-CENTER REPULSION PART OF THE FOCK
! MATRIX
! ON INPUT  PTOT = TOTAL DENSITY MATRIX.
!           P    = ALPHA OR BETA DENSITY MATRIX.
!           W    = TWO-ELECTRON INTEGRAL MATRIX.
!
!  ON OUTPUT F   = PARTIAL FOCK MATRIX
!***********************************************************************
! COSMO change
! end of COSMO change
!
!   Dummy statements - WJ and WK are to be used for polymer work
!
      a = wj(1) + wk(1)
!
!   SET UP ARRAY OF (I*(I-1))/2
!
      do i = 1, norbs 
        ifact(i) = (i*(i - 1))/2 
      end do 
      do ii = 1, numat 
        ia = nfirst(ii) 
        ib = nlast(ii) 
        do jj = 1, ii - 1 
          ja = nfirst(jj) 
          jb = nlast(jj) 
          ijw = nw(ii) - 1 
          do i = ia, ib 
            ka = ifact(i) 
            aa = 2.0D00 
            do j = ia, i 
              if (i == j) aa = 1.0D00 
              ijw = ijw + 1 
              kb = ifact(j) 
              ij = ka + j 
              klw = nw(jj) - 1 
              do k = ja, jb 
                kc = ifact(k) 
                ik = ka + k 
                jk = kb + k 
                bb = 2.0D00 
                do l = ja, k 
                  if (k == l) bb = 1.0D00 
                  il = ka + l 
                  jl = kb + l 
                  kl = kc + l 
                  klw = klw + 1 
                  a = w(ijw,klw) 
                  f(ij) = f(ij) + bb*a*ptot(kl) 
                  f(kl) = f(kl) + aa*a*ptot(ij) 
                  a = a*aa*bb*0.25D0 
                  f(ik) = f(ik) - a*p(jl) 
                  f(il) = f(il) - a*p(jk) 
                  f(jk) = f(jk) - a*p(il) 
                  f(jl) = f(jl) - a*p(ik) 
                end do 
              end do 
            end do 
          end do 
        end do 
      end do 
! COSMO change
! The following routine adds the dielectric corretion to F
      if (useps) call addfck (p) 
! A. Klamt 18.7.91
! end of COSMO change
      return  
      end subroutine fockd2 


      subroutine fordd 
!-----------------------------------------------
!   M o d u l e s 
!-----------------------------------------------
      USE mndod_C, only : indx, index, ch, ind2, isym, inddd, inddp, indpp 
!     *
!     DEFINITION OF INDICES AND LOGICAL VARIABLES.
!     *
!...Translated by Pacific-Sierra Research 77to90  4.4G  12:41:19  03/10/06  
!...Switches: -rl INDDO=2 INDIF=2 
      implicit none
!-----------------------------------------------
!   L o c a l   V a r i a b l e s
!-----------------------------------------------
      integer :: i, j, l
!-----------------------------------------------
!     *
!     INDEX(I,J) AND INDX(I,J) DEFINE ADDRESSES IN LOWER TRIANGLE
!     BY DIFFERENT CONVENTIONS.
!     INDEX(I,J) = 1,2,3 ..  FOR (I,J)=(1,1),(2,1),(3,1),..,(2,2),(3,2)
!     INDX(I,J)  = 1,2,3 ..  FOR (I,J)=(1,1),(2,1),(2,2),(3,1),(3,2) ..
!     INDX(I,J)    CORRESPONDS TO THE USUAL PAIR INDEX.
!     INDEX(J,I) = INDEX(I,J)
!     INDX(J,I)  = INDX(I,J)
!     *
!     *
!     COEFFICIENTS RELATING ANALYTICAL AND POINT-CHARGE MULTIPOLE
!     MOMENTS, SEE EQUATION (17) AND TABLE 2 OF TCA PAPER.
!     *
!     FIRST  INDEX          STANDARD PAIR INDEX (SPD BASIS)
!     SECOND INDEX          L QUANTUM NUMBER FOR MULTIPOLE MOMENT
!     THIRD  INDEX          M QUANTUM NUMBER FOR MULTIPOLE MOMENT
!     *
!
      do i = 1, 9 
        do j = 1, i 
          index(i,j) = (-(j*(j - 1))/2) + i + 9*(j - 1) 
          indx(i,j) = (i*(i - 1))/2 + j 
          index(j,i) = index(i,j) 
          indx(j,i) = indx(i,j) 
        end do 
      end do 
!
      ind2 = 0 
!
!   SP-SP
      ind2(1,1) = 1 
      ind2(1,2) = 2 
      ind2(1,10) = 3 
      ind2(1,18) = 4 
      ind2(1,25) = 5 
      ind2(2,1) = 6 
      ind2(2,2) = 7 
      ind2(2,10) = 8 
      ind2(2,18) = 9 
      ind2(2,25) = 10 
      ind2(10,1) = 11 
      ind2(10,2) = 12 
      ind2(10,10) = 13 
      ind2(10,18) = 14 
      ind2(10,25) = 15 
      ind2(3,3) = 16 
      ind2(3,11) = 17 
      ind2(11,3) = 18 
      ind2(11,11) = 19 
      ind2(18,1) = 20 
      ind2(18,2) = 21 
      ind2(18,10) = 22 
      ind2(18,18) = 23 
      ind2(18,25) = 24 
      ind2(4,4) = 25 
      ind2(4,12) = 26 
      ind2(12,4) = 27 
      ind2(12,12) = 28 
      ind2(19,19) = 29 
      ind2(25,1) = 30 
      ind2(25,2) = 31 
      ind2(25,10) = 32 
      ind2(25,18) = 33 
      ind2(25,25) = 34 
!   SPD-SPD
      ind2(1,5) = 35 
      ind2(1,13) = 36 
      ind2(1,31) = 37 
      ind2(1,21) = 38 
      ind2(1,36) = 39 
      ind2(1,28) = 40 
      ind2(1,40) = 41 
      ind2(1,43) = 42 
      ind2(1,45) = 43 
      ind2(2,5) = 44 
      ind2(2,13) = 45 
      ind2(2,31) = 46 
      ind2(2,21) = 47 
      ind2(2,36) = 48 
      ind2(2,28) = 49 
      ind2(2,40) = 50 
      ind2(2,43) = 51 
      ind2(2,45) = 52 
      ind2(10,5) = 53 
      ind2(10,13) = 54 
      ind2(10,31) = 55 
      ind2(10,21) = 56 
      ind2(10,36) = 57 
      ind2(10,28) = 58 
      ind2(10,40) = 59 
      ind2(10,43) = 60 
      ind2(10,45) = 61 
      ind2(3,20) = 62 
      ind2(3,6) = 63 
      ind2(3,14) = 64 
      ind2(3,32) = 65 
      ind2(3,23) = 66 
      ind2(3,38) = 67 
      ind2(3,30) = 68 
      ind2(3,42) = 69 
      ind2(11,20) = 70 
      ind2(11,6) = 71 
      ind2(11,14) = 72 
      ind2(11,32) = 73 
      ind2(11,23) = 74 
      ind2(11,38) = 75 
      ind2(11,30) = 76 
      ind2(11,42) = 77 
      ind2(18,5) = 78 
      ind2(18,13) = 79 
      ind2(18,31) = 80 
      ind2(18,21) = 81 
      ind2(18,36) = 82 
      ind2(18,28) = 83 
      ind2(18,40) = 84 
      ind2(18,8) = 85 
      ind2(18,16) = 86 
      ind2(18,34) = 87 
      ind2(18,43) = 88 
      ind2(18,45) = 89 
      ind2(4,26) = 90 
      ind2(4,7) = 91 
      ind2(4,15) = 92 
      ind2(4,33) = 93 
      ind2(4,29) = 94 
      ind2(4,41) = 95 
      ind2(4,24) = 96 
      ind2(4,39) = 97 
      ind2(12,26) = 98 
      ind2(12,7) = 99 
      ind2(12,15) = 100 
      ind2(12,33) = 101 
      ind2(12,29) = 102 
      ind2(12,41) = 103 
      ind2(12,24) = 104 
      ind2(12,39) = 105 
      ind2(19,27) = 106 
      ind2(19,22) = 107 
      ind2(19,37) = 108 
      ind2(19,9) = 109 
      ind2(19,17) = 110 
      ind2(19,35) = 111 
      ind2(25,5) = 112 
      ind2(25,13) = 113 
      ind2(25,31) = 114 
      ind2(25,21) = 115 
      ind2(25,36) = 116 
      ind2(25,28) = 117 
      ind2(25,40) = 118 
      ind2(25,8) = 119 
      ind2(25,16) = 120 
      ind2(25,34) = 121 
      ind2(25,43) = 122 
      ind2(25,45) = 123 
      ind2(5,1) = 124 
      ind2(5,2) = 125 
      ind2(5,10) = 126 
      ind2(5,18) = 127 
      ind2(5,25) = 128 
      ind2(5,5) = 129 
      ind2(5,13) = 130 
      ind2(5,31) = 131 
      ind2(5,21) = 132 
      ind2(5,36) = 133 
      ind2(5,28) = 134 
      ind2(5,40) = 135 
      ind2(5,43) = 136 
      ind2(5,45) = 137 
      ind2(13,1) = 138 
      ind2(13,2) = 139 
      ind2(13,10) = 140 
      ind2(13,18) = 141 
      ind2(13,25) = 142 
      ind2(13,5) = 143 
      ind2(13,13) = 144 
      ind2(13,31) = 145 
      ind2(13,21) = 146 
      ind2(13,36) = 147 
      ind2(13,28) = 148 
      ind2(13,40) = 149 
      ind2(13,43) = 150 
      ind2(13,45) = 151 
      ind2(20,3) = 152 
      ind2(20,11) = 153 
      ind2(20,20) = 154 
      ind2(20,6) = 155 
      ind2(20,14) = 156 
      ind2(20,32) = 157 
      ind2(20,23) = 158 
      ind2(20,38) = 159 
      ind2(20,30) = 160 
      ind2(20,42) = 161 
      ind2(26,4) = 162 
      ind2(26,12) = 163 
      ind2(26,26) = 164 
      ind2(26,7) = 165 
      ind2(26,15) = 166 
      ind2(26,33) = 167 
      ind2(26,29) = 168 
      ind2(26,41) = 169 
      ind2(26,24) = 170 
      ind2(26,39) = 171 
      ind2(31,1) = 172 
      ind2(31,2) = 173 
      ind2(31,10) = 174 
      ind2(31,18) = 175 
      ind2(31,25) = 176 
      ind2(31,5) = 177 
      ind2(31,13) = 178 
      ind2(31,31) = 179 
      ind2(31,21) = 180 
      ind2(31,36) = 181 
      ind2(31,28) = 182 
      ind2(31,40) = 183 
      ind2(31,43) = 184 
      ind2(31,45) = 185 
      ind2(6,3) = 186 
      ind2(6,11) = 187 
      ind2(6,20) = 188 
      ind2(6,6) = 189 
      ind2(6,14) = 190 
      ind2(6,32) = 191 
      ind2(6,23) = 192 
      ind2(6,38) = 193 
      ind2(6,30) = 194 
      ind2(6,42) = 195 
      ind2(14,3) = 196 
      ind2(14,11) = 197 
      ind2(14,20) = 198 
      ind2(14,6) = 199 
      ind2(14,14) = 200 
      ind2(14,32) = 201 
      ind2(14,23) = 202 
      ind2(14,38) = 203 
      ind2(14,30) = 204 
      ind2(14,42) = 205 
      ind2(21,1) = 206 
      ind2(21,2) = 207 
      ind2(21,10) = 208 
      ind2(21,18) = 209 
      ind2(21,25) = 210 
      ind2(21,5) = 211 
      ind2(21,13) = 212 
      ind2(21,31) = 213 
      ind2(21,21) = 214 
      ind2(21,36) = 215 
      ind2(21,28) = 216 
      ind2(21,40) = 217 
      ind2(21,8) = 218 
      ind2(21,16) = 219 
      ind2(21,34) = 220 
      ind2(21,43) = 221 
      ind2(21,45) = 222 
      ind2(27,19) = 223 
      ind2(27,27) = 224 
      ind2(27,22) = 225 
      ind2(27,37) = 226 
      ind2(27,9) = 227 
      ind2(27,17) = 228 
      ind2(27,35) = 229 
      ind2(32,3) = 230 
      ind2(32,11) = 231 
      ind2(32,20) = 232 
      ind2(32,6) = 233 
      ind2(32,14) = 234 
      ind2(32,32) = 235 
      ind2(32,23) = 236 
      ind2(32,38) = 237 
      ind2(32,30) = 238 
      ind2(32,42) = 239 
      ind2(36,1) = 240 
      ind2(36,2) = 241 
      ind2(36,10) = 242 
      ind2(36,18) = 243 
      ind2(36,25) = 244 
      ind2(36,5) = 245 
      ind2(36,13) = 246 
      ind2(36,31) = 247 
      ind2(36,21) = 248 
      ind2(36,36) = 249 
      ind2(36,28) = 250 
      ind2(36,40) = 251 
      ind2(36,8) = 252 
      ind2(36,16) = 253 
      ind2(36,34) = 254 
      ind2(36,43) = 255 
      ind2(36,45) = 256 
      ind2(7,4) = 257 
      ind2(7,12) = 258 
      ind2(7,26) = 259 
      ind2(7,7) = 260 
      ind2(7,15) = 261 
      ind2(7,33) = 262 
      ind2(7,29) = 263 
      ind2(7,41) = 264 
      ind2(7,24) = 265 
      ind2(7,39) = 266 
      ind2(15,4) = 267 
      ind2(15,12) = 268 
      ind2(15,26) = 269 
      ind2(15,7) = 270 
      ind2(15,15) = 271 
      ind2(15,33) = 272 
      ind2(15,29) = 273 
      ind2(15,41) = 274 
      ind2(15,24) = 275 
      ind2(15,39) = 276 
      ind2(22,19) = 277 
      ind2(22,27) = 278 
      ind2(22,22) = 279 
      ind2(22,37) = 280 
      ind2(22,9) = 281 
      ind2(22,17) = 282 
      ind2(22,35) = 283 
      ind2(28,1) = 284 
      ind2(28,2) = 285 
      ind2(28,10) = 286 
      ind2(28,18) = 287 
      ind2(28,25) = 288 
      ind2(28,5) = 289 
      ind2(28,13) = 290 
      ind2(28,31) = 291 
      ind2(28,21) = 292 
      ind2(28,36) = 293 
      ind2(28,28) = 294 
      ind2(28,40) = 295 
      ind2(28,8) = 296 
      ind2(28,16) = 297 
      ind2(28,34) = 298 
      ind2(28,43) = 299 
      ind2(28,45) = 300 
      ind2(33,4) = 301 
      ind2(33,12) = 302 
      ind2(33,26) = 303 
      ind2(33,7) = 304 
      ind2(33,15) = 305 
      ind2(33,33) = 306 
      ind2(33,29) = 307 
      ind2(33,41) = 308 
      ind2(33,24) = 309 
      ind2(33,39) = 310 
      ind2(37,19) = 311 
      ind2(37,27) = 312 
      ind2(37,22) = 313 
      ind2(37,37) = 314 
      ind2(37,9) = 315 
      ind2(37,17) = 316 
      ind2(37,35) = 317 
      ind2(40,1) = 318 
      ind2(40,2) = 319 
      ind2(40,10) = 320 
      ind2(40,18) = 321 
      ind2(40,25) = 322 
      ind2(40,5) = 323 
      ind2(40,13) = 324 
      ind2(40,31) = 325 
      ind2(40,21) = 326 
      ind2(40,36) = 327 
      ind2(40,28) = 328 
      ind2(40,40) = 329 
      ind2(40,8) = 330 
      ind2(40,16) = 331 
      ind2(40,34) = 332 
      ind2(40,43) = 333 
      ind2(40,45) = 334 
      ind2(8,18) = 335 
      ind2(8,25) = 336 
      ind2(8,21) = 337 
      ind2(8,36) = 338 
      ind2(8,28) = 339 
      ind2(8,40) = 340 
      ind2(8,8) = 341 
      ind2(8,16) = 342 
      ind2(8,34) = 343 
      ind2(16,18) = 344 
      ind2(16,25) = 345 
      ind2(16,21) = 346 
      ind2(16,36) = 347 
      ind2(16,28) = 348 
      ind2(16,40) = 349 
      ind2(16,8) = 350 
      ind2(16,16) = 351 
      ind2(16,34) = 352 
      ind2(23,3) = 353 
      ind2(23,11) = 354 
      ind2(23,20) = 355 
      ind2(23,6) = 356 
      ind2(23,14) = 357 
      ind2(23,32) = 358 
      ind2(23,23) = 359 
      ind2(23,38) = 360 
      ind2(23,30) = 361 
      ind2(23,42) = 362 
      ind2(29,4) = 363 
      ind2(29,12) = 364 
      ind2(29,26) = 365 
      ind2(29,7) = 366 
      ind2(29,15) = 367 
      ind2(29,33) = 368 
      ind2(29,29) = 369 
      ind2(29,41) = 370 
      ind2(29,24) = 371 
      ind2(29,39) = 372 
      ind2(34,18) = 373 
      ind2(34,25) = 374 
      ind2(34,21) = 375 
      ind2(34,36) = 376 
      ind2(34,28) = 377 
      ind2(34,40) = 378 
      ind2(34,8) = 379 
      ind2(34,16) = 380 
      ind2(34,34) = 381 
      ind2(38,3) = 382 
      ind2(38,11) = 383 
      ind2(38,20) = 384 
      ind2(38,6) = 385 
      ind2(38,14) = 386 
      ind2(38,32) = 387 
      ind2(38,23) = 388 
      ind2(38,38) = 389 
      ind2(38,30) = 390 
      ind2(38,42) = 391 
      ind2(41,4) = 392 
      ind2(41,12) = 393 
      ind2(41,26) = 394 
      ind2(41,7) = 395 
      ind2(41,15) = 396 
      ind2(41,33) = 397 
      ind2(41,29) = 398 
      ind2(41,41) = 399 
      ind2(41,24) = 400 
      ind2(41,39) = 401 
      ind2(43,1) = 402 
      ind2(43,2) = 403 
      ind2(43,10) = 404 
      ind2(43,18) = 405 
      ind2(43,25) = 406 
      ind2(43,5) = 407 
      ind2(43,13) = 408 
      ind2(43,31) = 409 
      ind2(43,21) = 410 
      ind2(43,36) = 411 
      ind2(43,28) = 412 
      ind2(43,40) = 413 
      ind2(43,43) = 414 
      ind2(43,45) = 415 
      ind2(9,19) = 416 
      ind2(9,27) = 417 
      ind2(9,22) = 418 
      ind2(9,37) = 419 
      ind2(9,9) = 420 
      ind2(9,17) = 421 
      ind2(9,35) = 422 
      ind2(17,19) = 423 
      ind2(17,27) = 424 
      ind2(17,22) = 425 
      ind2(17,37) = 426 
      ind2(17,9) = 427 
      ind2(17,17) = 428 
      ind2(17,35) = 429 
      ind2(24,4) = 430 
      ind2(24,12) = 431 
      ind2(24,26) = 432 
      ind2(24,7) = 433 
      ind2(24,15) = 434 
      ind2(24,33) = 435 
      ind2(24,29) = 436 
      ind2(24,41) = 437 
      ind2(24,24) = 438 
      ind2(24,39) = 439 
      ind2(30,3) = 440 
      ind2(30,11) = 441 
      ind2(30,20) = 442 
      ind2(30,6) = 443 
      ind2(30,14) = 444 
      ind2(30,32) = 445 
      ind2(30,23) = 446 
      ind2(30,38) = 447 
      ind2(30,30) = 448 
      ind2(30,42) = 449 
      ind2(35,19) = 450 
      ind2(35,27) = 451 
      ind2(35,22) = 452 
      ind2(35,37) = 453 
      ind2(35,9) = 454 
      ind2(35,17) = 455 
      ind2(35,35) = 456 
      ind2(39,4) = 457 
      ind2(39,12) = 458 
      ind2(39,26) = 459 
      ind2(39,7) = 460 
      ind2(39,15) = 461 
      ind2(39,33) = 462 
      ind2(39,29) = 463 
      ind2(39,41) = 464 
      ind2(39,24) = 465 
      ind2(39,39) = 466 
      ind2(42,3) = 467 
      ind2(42,11) = 468 
      ind2(42,20) = 469 
      ind2(42,6) = 470 
      ind2(42,14) = 471 
      ind2(42,32) = 472 
      ind2(42,23) = 473 
      ind2(42,38) = 474 
      ind2(42,30) = 475 
      ind2(42,42) = 476 
      ind2(44,44) = 477 
      ind2(45,1) = 478 
      ind2(45,2) = 479 
      ind2(45,10) = 480 
      ind2(45,18) = 481 
      ind2(45,25) = 482 
      ind2(45,5) = 483 
      ind2(45,13) = 484 
      ind2(45,31) = 485 
      ind2(45,21) = 486 
      ind2(45,36) = 487 
      ind2(45,28) = 488 
      ind2(45,40) = 489 
      ind2(45,43) = 490 
      ind2(45,45) = 491 
      isym = 0 
!
      isym(40) = 38 
      isym(41) = 39 
      isym(43) = 42 
      isym(49) = 47 
      isym(50) = 48 
      isym(52) = 51 
      isym(58) = 56 
      isym(59) = 57 
      isym(61) = 60 
      isym(68) = 66 
      isym(69) = 67 
      isym(76) = 74 
      isym(77) = 75 
      isym(89) = 88 
      isym(90) = 62 
      isym(91) = 63 
      isym(92) = 64 
      isym(93) = 65 
      isym(94) = -66 
      isym(95) = -67 
      isym(96) = 66 
      isym(97) = 67 
      isym(98) = 70 
      isym(99) = 71 
      isym(100) = 72 
      isym(101) = 73 
      isym(102) = -74 
      isym(103) = -75 
      isym(104) = 74 
      isym(105) = 75 
      isym(106) = 86 
      isym(107) = 86 
      isym(109) = 85 
      isym(110) = 86 
      isym(111) = 87 
      isym(112) = 78 
      isym(113) = 79 
      isym(114) = 80 
      isym(115) = 83 
      isym(116) = 84 
      isym(117) = 81 
      isym(118) = 82 
      isym(119) = -85 
      isym(120) = -86 
      isym(121) = -87 
      isym(122) = 88 
      isym(123) = 88 
      isym(128) = 127 
      isym(134) = 132 
      isym(135) = 133 
      isym(137) = 136 
      isym(142) = 141 
      isym(148) = 146 
      isym(149) = 147 
      isym(151) = 150 
      isym(160) = 158 
      isym(161) = 159 
      isym(162) = 152 
      isym(163) = 153 
      isym(164) = 154 
      isym(165) = 155 
      isym(166) = 156 
      isym(167) = 157 
      isym(168) = -158 
      isym(169) = -159 
      isym(170) = 158 
      isym(171) = 159 
      isym(176) = 175 
      isym(182) = 180 
      isym(183) = 181 
      isym(185) = 184 
      isym(194) = 192 
      isym(195) = 193 
      isym(204) = 202 
      isym(205) = 203 
      isym(222) = 221 
      isym(224) = 219 
      isym(225) = 219 
      isym(227) = 218 
      isym(228) = 219 
      isym(229) = 220 
      isym(238) = 236 
      isym(239) = 237 
      isym(256) = 255 
      isym(257) = 186 
      isym(258) = 187 
      isym(259) = 188 
      isym(260) = 189 
      isym(261) = 190 
      isym(262) = 191 
      isym(263) = -192 
      isym(264) = -193 
      isym(265) = 192 
      isym(266) = 193 
      isym(267) = 196 
      isym(268) = 197 
      isym(269) = 198 
      isym(270) = 199 
      isym(271) = 200 
      isym(272) = 201 
      isym(273) = -202 
      isym(274) = -203 
      isym(275) = 202 
      isym(276) = 203 
      isym(277) = 223 
      isym(278) = 219 
      isym(279) = 219 
      isym(280) = 226 
      isym(281) = 218 
      isym(282) = 219 
      isym(283) = 220 
      isym(284) = 206 
      isym(285) = 207 
      isym(286) = 208 
      isym(287) = 210 
      isym(288) = 209 
      isym(289) = 211 
      isym(290) = 212 
      isym(291) = 213 
      isym(292) = 216 
      isym(293) = 217 
      isym(294) = 214 
      isym(295) = 215 
      isym(296) = -218 
      isym(297) = -219 
      isym(298) = -220 
      isym(299) = 221 
      isym(300) = 221 
      isym(301) = 230 
      isym(302) = 231 
      isym(303) = 232 
      isym(304) = 233 
      isym(305) = 234 
      isym(306) = 235 
      isym(307) = -236 
      isym(308) = -237 
      isym(309) = 236 
      isym(310) = 237 
      isym(312) = 253 
      isym(313) = 253 
      isym(315) = 252 
      isym(316) = 253 
      isym(317) = 254 
      isym(318) = 240 
      isym(319) = 241 
      isym(320) = 242 
      isym(321) = 244 
      isym(322) = 243 
      isym(323) = 245 
      isym(324) = 246 
      isym(325) = 247 
      isym(326) = 250 
      isym(327) = 251 
      isym(328) = 248 
      isym(329) = 249 
      isym(330) = -252 
      isym(331) = -253 
      isym(332) = -254 
      isym(333) = 255 
      isym(334) = 255 
      isym(336) = -335 
      isym(339) = -337 
      isym(340) = -338 
      isym(342) = 337 
      isym(344) = 223 
      isym(345) = -223 
      isym(346) = 219 
      isym(347) = 226 
      isym(348) = -219 
      isym(349) = -226 
      isym(350) = 218 
      isym(351) = 219 
      isym(352) = 220 
      isym(363) = -353 
      isym(364) = -354 
      isym(365) = -355 
      isym(366) = -356 
      isym(367) = -357 
      isym(368) = -358 
      isym(369) = 359 
      isym(370) = 360 
      isym(371) = -361 
      isym(372) = -362 
      isym(374) = -373 
      isym(377) = -375 
      isym(378) = -376 
      isym(380) = 375 
      isym(392) = -382 
      isym(393) = -383 
      isym(394) = -384 
      isym(395) = -385 
      isym(396) = -386 
      isym(397) = -387 
      isym(398) = 388 
      isym(399) = 389 
      isym(400) = -390 
      isym(401) = -391 
      isym(406) = 405 
      isym(412) = 410 
      isym(413) = 411 
      isym(416) = 335 
      isym(417) = 337 
      isym(418) = 337 
      isym(419) = 338 
      isym(420) = 341 
      isym(421) = 337 
      isym(422) = 343 
      isym(423) = 223 
      isym(424) = 219 
      isym(425) = 219 
      isym(426) = 226 
      isym(427) = 218 
      isym(428) = 219 
      isym(429) = 220 
      isym(430) = 353 
      isym(431) = 354 
      isym(432) = 355 
      isym(433) = 356 
      isym(434) = 357 
      isym(435) = 358 
      isym(436) = -361 
      isym(437) = -362 
      isym(438) = 359 
      isym(439) = 360 
      isym(440) = 353 
      isym(441) = 354 
      isym(442) = 355 
      isym(443) = 356 
      isym(444) = 357 
      isym(445) = 358 
      isym(446) = 361 
      isym(447) = 362 
      isym(448) = 359 
      isym(449) = 360 
      isym(450) = 373 
      isym(451) = 375 
      isym(452) = 375 
      isym(453) = 376 
      isym(454) = 379 
      isym(455) = 375 
      isym(456) = 381 
      isym(457) = 382 
      isym(458) = 383 
      isym(459) = 384 
      isym(460) = 385 
      isym(461) = 386 
      isym(462) = 387 
      isym(463) = -390 
      isym(464) = -391 
      isym(465) = 388 
      isym(466) = 389 
      isym(467) = 382 
      isym(468) = 383 
      isym(469) = 384 
      isym(470) = 385 
      isym(471) = 386 
      isym(472) = 387 
      isym(473) = 390 
      isym(474) = 391 
      isym(475) = 388 
      isym(476) = 389 
      isym(478) = 402 
      isym(479) = 403 
      isym(480) = 404 
      isym(481) = 405 
      isym(482) = 405 
      isym(483) = 407 
      isym(484) = 408 
      isym(485) = 409 
      isym(486) = 410 
      isym(487) = 411 
      isym(488) = 410 
      isym(489) = 411 
      isym(490) = 415 
      isym(491) = 414 
!   *
      do i = 1, 45 
        do l = 0, 2 
          ch(i,l,(-l):l) = 0.d0 
        end do 
      end do 
!   *
! *** THE STANDARD MNDO93 CODE DEFINES THE FOLLOWING CONSTANTS
! *** MORE PRECISELY (BUT WITH A DIFFERENT NUMBERING SCHEME).
!     PARAMETER (CLM3  = 0.13333333333333D+01)
!     PARAMETER (CLM6  =-0.66666666666667D+00)
!     PARAMETER (CLM10 =-0.66666666666667D+00)
!     PARAMETER (CLM11 = 0.11547005383793D+01)
!     PARAMETER (CLM12 = 0.11547005383793D+01)
!     PARAMETER (CLM13 =-0.57735026918963D+00)
!     PARAMETER (CLM15 = 0.13333333333333D+01)
!     PARAMETER (CLM20 = 0.57735026918963D+00)
!     PARAMETER (CLM21 = 0.66666666666667D+00)
!     PARAMETER (CLM28 = 0.66666666666667D+00)
!     PARAMETER (CLM33 =-0.11547005383793D+01)
!     PARAMETER (CLM36 =-0.13333333333333D+01)
!     PARAMETER (CLM45 =-0.13333333333333D+01)
! *** PLEASE MAKE THE OBVIOUS CORRECTIONS.
      ch(1,0,0) = 1.d0 
      ch(2,1,0) = 1.d0 
      ch(3,1,1) = 1.d0 
      ch(4,1,-1) = 1.d0 
      ch(5,2,0) = 1.15470054D0 
      ch(6,2,1) = 1.d0 
      ch(7,2,-1) = 1.d0 
      ch(8,2,2) = 1.d0 
      ch(9,2,-2) = 1.d0 
      ch(10,0,0) = 1.d0 
      ch(10,2,0) = 1.33333333D0 
      ch(11,2,1) = 1.d0 
      ch(12,2,-1) = 1.d0 
      ch(13,1,0) = 1.15470054D0 
      ch(14,1,1) = 1.d0 
      ch(15,1,-1) = 1.d0 
      ch(18,0,0) = 1.d0 
      ch(18,2,0) = -.66666667D0 
      ch(18,2,2) = 1.d0 
      ch(19,2,-2) = 1.d0 
      ch(20,1,1) = -.57735027D0 
      ch(21,1,0) = 1.d0 
      ch(23,1,1) = 1.d0 
      ch(24,1,-1) = 1.d0 
      ch(25,0,0) = 1.d0 
      ch(25,2,0) = -.66666667D0 
      ch(25,2,2) = -1.d0 
      ch(26,1,-1) = -.57735027D0 
      ch(28,1,0) = 1.d0 
      ch(29,1,-1) = -1.d0 
      ch(30,1,1) = 1.d0 
      ch(31,0,0) = 1.d0 
      ch(31,2,0) = 1.33333333D0 
      ch(32,2,1) = .57735027D0 
      ch(33,2,-1) = .57735027D0 
      ch(34,2,2) = -1.15470054D0 
      ch(35,2,-2) = -1.15470054D0 
      ch(36,0,0) = 1.d0 
      ch(36,2,0) = .66666667D0 
      ch(36,2,2) = 1.d0 
      ch(37,2,-2) = 1.d0 
      ch(38,2,1) = 1.d0 
      ch(39,2,-1) = 1.d0 
      ch(40,0,0) = 1.d0 
      ch(40,2,0) = .66666667D0 
      ch(40,2,2) = -1.d0 
      ch(41,2,-1) = -1.d0 
      ch(42,2,1) = 1.d0 
      ch(43,0,0) = 1.d0 
      ch(43,2,0) = -1.33333333D0 
      ch(45,0,0) = 1.d0 
      ch(45,2,0) = -1.33333333D0 
!
!   INDPP
      indpp(1,1) = 1 
      indpp(2,1) = 4 
      indpp(3,1) = 5 
      indpp(1,2) = 4 
      indpp(2,2) = 2 
      indpp(3,2) = 6 
      indpp(1,3) = 5 
      indpp(2,3) = 6 
      indpp(3,3) = 3 
!   INDDP
      inddp(1,1) = 1 
      inddp(2,1) = 4 
      inddp(3,1) = 7 
      inddp(4,1) = 10 
      inddp(5,1) = 13 
      inddp(1,2) = 2 
      inddp(2,2) = 5 
      inddp(3,2) = 8 
      inddp(4,2) = 11 
      inddp(5,2) = 14 
      inddp(1,3) = 3 
      inddp(2,3) = 6 
      inddp(3,3) = 9 
      inddp(4,3) = 12 
      inddp(5,3) = 15 
!   INDDD
      inddd(1,1) = 1 
      inddd(2,1) = 6 
      inddd(3,1) = 7 
      inddd(4,1) = 9 
      inddd(5,1) = 12 
      inddd(1,2) = 6 
      inddd(2,2) = 2 
      inddd(3,2) = 8 
      inddd(4,2) = 10 
      inddd(5,2) = 13 
      inddd(1,3) = 7 
      inddd(2,3) = 8 
      inddd(3,3) = 3 
      inddd(4,3) = 11 
      inddd(5,3) = 14 
      inddd(1,4) = 9 
      inddd(2,4) = 10 
      inddd(3,4) = 11 
      inddd(4,4) = 4 
      inddd(5,4) = 15 
      inddd(1,5) = 12 
      inddd(2,5) = 13 
      inddd(3,5) = 14 
      inddd(4,5) = 15 
      inddd(5,5) = 5 
      return  
      end subroutine fordd 


      subroutine formxd(wd, nwii, nwjj, wca, wcb, ca, na, cb, nb) 
!-----------------------------------------------
!   M o d u l e s 
!-----------------------------------------------
      USE vast_kind_param, ONLY:  double 
      USE molkst_C, only : lm6, numcal
!...Translated by Pacific-Sierra Research 77to90  4.4G  12:41:19  03/10/06  
!...Switches: -rl INDDO=2 INDIF=2 
      implicit none
!-----------------------------------------------
!   D u m m y   A r g u m e n t s
!-----------------------------------------------
      integer , intent(in) :: nwii 
      integer , intent(in) :: nwjj 
      integer , intent(in) :: na 
      integer , intent(in) :: nb 
      real(double) , intent(in) :: wd(lm6,lm6) 
      real(double) , intent(inout) :: wca(45) 
      real(double) , intent(inout) :: wcb(45) 
      real(double) , intent(in) :: ca(45) 
      real(double) , intent(in) :: cb(45) 
!-----------------------------------------------
!   L o c a l   V a r i a b l e s
!-----------------------------------------------
      integer :: icalcn, ij, i, j, kl, k, l 
      real(double) :: aa, sum, bb 

      save icalcn 
!-----------------------------------------------
!***********************************************************************
!
!    EACH OF THE NA ELEMENTS OF WCA WILL ADD ON THE NB ELECTROSTATIC
!    TERMS FROM ATOM B IN CB
!
!    EACH OF THE NB ELEMENTS OF WCB WILL ADD ON THE NA ELECTROSTATIC
!    TERMS FROM ATOM A IN CA
!
!    BOTH SUMS WILL INVOLVE THE NA*NB TERMS IN ARRAY W.  ONCE USED,
!    W WILL BE INCREMENTED BY NA*NB.
!
! NA=NUMBER OF ATOMIC ORBITALS ON ATOM `A'.
! NB=NUMBER OF ATOMIC ORBITALS ON ATOM `B'.
!
!***********************************************************************
      data icalcn/ 0/  
      if (icalcn /= numcal) icalcn = numcal 
      ij = 0 
      do i = 1, na 
        aa = 1.D0 
        do j = 1, i 
          if (i == j) aa = 0.5D0 
          ij = ij + 1 
          sum = 0.D0 
          kl = 0 
          do k = 1, nb 
            bb = 1.D0 
            do l = 1, k 
              if (k == l) bb = 0.5D0 
              kl = kl + 1 
              sum = sum + cb(kl)*wd(kl+nwjj,ij+nwii)*bb 
            end do 
          end do 
          wca(ij) = wca(ij) + sum*aa 
        end do 
      end do 
      ij = 0 
      do i = 1, nb 
        aa = 1.D0 
        do j = 1, i 
          if (i == j) aa = 0.5D0 
          ij = ij + 1 
          sum = 0.D0 
          kl = 0 
          do k = 1, na 
            bb = 1.D0 
            do l = 1, k 
              if (k == l) bb = 0.5D0 
              kl = kl + 1 
              sum = sum + ca(kl)*wd(ij+nwjj,kl+nwii)*bb 
            end do 
          end do 
          wcb(ij) = wcb(ij) + sum*aa 
        end do 
      end do 
      return  
      end subroutine formxd 

