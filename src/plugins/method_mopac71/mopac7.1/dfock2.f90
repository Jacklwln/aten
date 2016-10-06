      subroutine dfock2(f, ptot, p, w, numat, nfirst, nlast, nati) 
!-----------------------------------------------
!   M o d u l e s 
!-----------------------------------------------
      USE vast_kind_param, ONLY:  double 
    !  USE work4_C, only : 
      use molkst_C, only : numcal, norbs
!***********************************************************************
!DECK MOPAC
!...Translated by Pacific-Sierra Research 77to90  4.4G  10:47:07  03/09/06  
!...Switches: -rl INDDO=2 INDIF=2 
!-----------------------------------------------
!   I n t e r f a c e   B l o c k s
!-----------------------------------------------
      use jab_I 
      use kab_I 
      implicit none
!-----------------------------------------------
!   G l o b a l   P a r a m e t e r s
!-----------------------------------------------
!-----------------------------------------------
!   D u m m y   A r g u m e n t s
!-----------------------------------------------
      integer , intent(in) :: numat 
      integer , intent(in) :: nati 
      integer , intent(in) :: nfirst(*) 
      integer , intent(in) :: nlast(*) 
      real(double)  :: f(*) 
      real(double) , intent(in) :: ptot(*) 
      real(double) , intent(in) :: p(*) 
      real(double)  :: w(*) 
!-----------------------------------------------
!   L o c a l   V a r i a b l e s
!-----------------------------------------------
      integer , dimension(:), allocatable :: ifact, i1fact 
      integer :: itype 
      integer , dimension(256) :: jindex 
      integer :: icalcn, i, m, j, ij, ji, k, ik, l, kl, lk, kk, ia, ib, jk, kj&
        , ii, jj, ja, jb, i1, j1, ll, kr, ka 
      real(double), dimension(16) :: pk, pja, pjb 
      real(double) :: sumdia, sumoff, sum, elrep
      real(double), dimension(:,:), allocatable :: ptot2

      save ifact, i1fact, itype, icalcn, ptot2
!-----------------------------------------------
!***********************************************************************
!
!     DFOCK2 ADDS THE 2-ELECTRON 2-CENTER REPULSION CONTRIBUTION TO
!     THE FOCK MATRIX DERIVATIVE WITHIN THE NDDO FORMALISMS.
!  INPUT
!     F    : 1-ELECTRON CONTRIBUTIONS DERIVATIVES.
!     PTOT : TOTAL DENSITY MATRIX.
!     P    : ALPHA OR BETA DENSITY MATRIX. = 0.5 * PTOT
!     W    : NON VANISHING TWO-ELECTRON INTEGRAL DERIVATIVES
!            (ORDERED AS DEFINED IN DHCORE).
!     NATI : # OF THE ATOM SUPPORTING THE VARYING CARTESIAN COORDINATE.
!  OUTPUT
!     F    : FOCK MATRIX DERIVATIVE WITH RESPECT TO THE CART. COORD.
!
!***********************************************************************
      data itype/ 1/  
      data icalcn/ 0/  
      if (icalcn /= numcal) then 
        if (allocated(ifact))  deallocate(ifact)
        if (allocated(i1fact)) deallocate(i1fact)
        if (allocated(ptot2))  deallocate(ptot2)
        allocate(ifact(norbs), i1fact(norbs), ptot2(numat,16))
        icalcn = numcal 
        itype = 1 
      endif 
   10 continue 
      select case (itype)  
      case default 
        do i = 1, norbs
          ifact(i) = (i*(i - 1))/2 
          i1fact(i) = ifact(i) + i 
        end do 
!
!   SET UP GATHER-SCATTER TYPE ARRAYS FOR USE WITH TWO-ELECTRON
!   INTEGRALS.  JINDEX ARE THE INDICES OF THE J-INTEGRALS FOR ATOM I
!   INTEGRALS.  JJNDEX ARE THE INDICES OF THE J-INTEGRALS FOR ATOM J
!               KINDEX ARE THE INDICES OF THE K-INTEGRALS
!
        m = 0 
        do i = 1, 4 
          do j = 1, 4 
            ij = min(i,j) 
            ji = i + j - ij 
            do k = 1, 4 
              ik = min(i,k) 
              do l = 1, 4 
                m = m + 1 
                kl = min(k,l) 
                lk = k + l - kl 
                jindex(m) = (ifact(ji)+ij)*10 + ifact(lk) + kl - 10 
              end do 
            end do 
          end do 
        end do 
          itype = 3 
        go to 10 
      case (3)  
        kk = 0 
        l = 0 
        do i = 1, numat 
          ia = nfirst(i) 
          ib = nlast(i) 
          m = 0 
          do j = ia, ib 
            do k = ia, ib 
              m = m + 1 
              jk = min(j,k) 
              kj = k + j - jk 
              jk = jk + (kj*(kj - 1))/2 
              ptot2(i,m) = ptot(jk) 
            end do 
          end do 
        end do 
        ii = nati 
        ia = nfirst(ii) 
        ib = nlast(ii) 
        do jj = 1, numat 
          if (ii == jj) cycle  
          ja = nfirst(jj) 
          jb = nlast(jj) 
          if (ib - ia>=3 .and. jb-ja>=3) then 
!
!                         HEAVY-ATOM  - HEAVY-ATOM
!
!   EXTRACT COULOMB TERMS
!
            pja = ptot2(ii,:) 
            pjb = ptot2(jj,:) 
!
!  COULOMB TERMS
!
            call jab (ia, ja, pja, pjb, w(kk+1), f) 
!VECTOR       CALL JAB(IA,JA,LLPERM,JINDEX, JJNDEX, PJA,PJB,W(KK+1),F)
!
!  EXCHANGE TERMS
!
!
!  EXTRACT INTERSECTION OF ATOMS II AND JJ IN THE SPIN DENSITY MATRIX
!
            if (ia > ja) then 
              l = 0 
              do i = ia, ib 
                if (jb - ja + 1 > 0) then 
                  pk(l+1:jb-ja+1+l) = p(ifact(i)+ja:jb+ifact(i)) 
                  l = jb - ja + 1 + l 
                endif 
              end do 
            else 
              l = 0 
              do i = ia, ib 
                if (jb - ja + 1 > 0) then 
                  pk(l+1:jb-ja+1+l) = p(ifact(ja:jb)+i) 
                  l = jb - ja + 1 + l 
                endif 
              end do 
            endif 
            i1 = ia 
            j1 = ja 
            call kab (ia, ja, pk, w(kk+1), f) 
!VECTOR       CALL KAB(IA,JA, PK, W(KK+1), KINDEX, F)
            ia = i1 
            ja = j1 
            kk = kk + 100 
          else if (ib - ia >= 3) then 
!
!                         LIGHT-ATOM  - HEAVY-ATOM
!
!
!   COULOMB TERMS
!
            sumdia = 0.D0 
            sumoff = 0.D0 
            ll = i1fact(ja) 
            k = 0 
            do i = 0, 3 
              j1 = ifact(ia+i) + ia - 1 
              do j = 0, i - 1 
                k = k + 1 
                j1 = j1 + 1 
                f(j1) = f(j1) + ptot(ll)*w(kk+k) 
                sumoff = sumoff + ptot(j1)*w(kk+k) 
              end do 
              j1 = j1 + 1 
              k = k + 1 
              f(j1) = f(j1) + ptot(ll)*w(kk+k) 
              sumdia = sumdia + ptot(j1)*w(kk+k) 
            end do 
            f(ll) = f(ll) + sumoff*2.D0 + sumdia 
!
!  EXCHANGE TERMS
!
!
!  EXTRACT INTERSECTION OF ATOMS II AND JJ IN THE SPIN DENSITY MATRIX
!
            if (ia > ja) then 
              k = 0 
              do i = ia, ib 
                i1 = ifact(i) + ja 
                sum = 0.D0 
                do j = ia, ib 
                  k = k + 1 
                  j1 = ifact(j) + ja 
                  sum = sum + p(j1)*w(kk+jindex(k)) 
                end do 
                f(i1) = f(i1) - sum 
              end do 
            else 
              k = 0 
              do i = ia, ib 
                i1 = ifact(ja) + i 
                sum = 0.D0 
                do j = ia, ib 
                  k = k + 1 
                  j1 = ifact(ja) + j 
                  sum = sum + p(j1)*w(kk+jindex(k)) 
                end do 
                f(i1) = f(i1) - sum 
              end do 
            endif 
            kk = kk + 10 
          else if (jb - ja >= 3) then 
!
!                         HEAVY-ATOM - LIGHT-ATOM
!
!
!   COULOMB TERMS
!
            sumdia = 0.D0 
            sumoff = 0.D0 
            ll = i1fact(ia) 
            k = 0 
            do i = 0, 3 
              j1 = ifact(ja+i) + ja - 1 
              do j = 0, i - 1 
                k = k + 1 
                j1 = j1 + 1 
                f(j1) = f(j1) + ptot(ll)*w(kk+k) 
                sumoff = sumoff + ptot(j1)*w(kk+k) 
              end do 
              j1 = j1 + 1 
              k = k + 1 
              f(j1) = f(j1) + ptot(ll)*w(kk+k) 
              sumdia = sumdia + ptot(j1)*w(kk+k) 
            end do 
            f(ll) = f(ll) + sumoff*2.D0 + sumdia 
!
!  EXCHANGE TERMS
!
!
!  EXTRACT INTERSECTION OF ATOMS II AND JJ IN THE SPIN DENSITY MATRIX
!
            if (ia > ja) then 
              k = ifact(ia) + ja 
              j = 0 
              do i = k, k + 3 
                sum = 0.D0 
                do l = k, k + 3 
                  j = j + 1 
                  sum = sum + p(l)*w(kk+jindex(j)) 
                end do 
                f(i) = f(i) - sum 
              end do 
            else 
              j = 0 
              do k = ja, ja + 3 
                i = ifact(k) + ia 
                sum = 0.D0 
                do ll = ja, ja + 3 
                  l = ifact(ll) + ia 
                  j = j + 1 
                  sum = sum + p(l)*w(kk+jindex(j)) 
                end do 
                f(i) = f(i) - sum 
              end do 
            endif 
            kk = kk + 10 
          else 
!
!                         LIGHT-ATOM - LIGHT-ATOM
!
            i1 = i1fact(ia) 
            j1 = i1fact(ja) 
            f(i1) = f(i1) + ptot(j1)*w(kk+1) 
            f(j1) = f(j1) + ptot(i1)*w(kk+1) 
            if (ia > ja) then 
              ij = i1 + ja - ia 
              f(ij) = f(ij) - p(ij)*w(kk+1) 
            else 
              ij = j1 + ia - ja 
              f(ij) = f(ij) - p(ij)*w(kk+1) 
            endif 
            kk = kk + 1 
          endif 
        end do 
        return  
      case (2)  
        kr = 0 
        ii = nati 
        ia = nfirst(ii) 
        ib = nlast(ii) 
        do jj = 1, numat 
          if (jj == ii) cycle  
          kr = kr + 1 
          elrep = w(kr) 
          ja = nfirst(jj) 
          jb = nlast(jj) 
          if (ja < ia) then 
            do i = ia, ib 
              ka = ifact(i) 
              kk = ka + i 
              do k = ja, jb 
                ll = i1fact(k) 
                ik = ka + k 
                f(kk) = f(kk) + ptot(ll)*elrep 
                f(ll) = f(ll) + ptot(kk)*elrep 
                f(ik) = f(ik) - p(ik)*elrep 
              end do 
            end do 
          else 
            do i = ia, ib 
              ka = ifact(i) 
              kk = ka + i 
              do k = ja, jb 
                ll = i1fact(k) 
                ik = ll + i - k 
                f(kk) = f(kk) + ptot(ll)*elrep 
                f(ll) = f(ll) + ptot(kk)*elrep 
                f(ik) = f(ik) - p(ik)*elrep 
              end do 
            end do 
          endif 
        end do 
        return  
      end select 
      end subroutine dfock2 
