  !                                                                            
  ! Copyright (C) 2010-2019 Samuel Ponce', Roxana Margine, Carla Verdi, Feliciano Giustino  
  !                                                                            
  ! This file is distributed under the terms of the GNU General Public         
  ! License. See the file `LICENSE' in the root directory of the               
  ! present distribution, or http://www.gnu.org/copyleft.gpl.txt .             
  !                                                                            
  !----------------------------------------------------------------------
  MODULE printing
  !----------------------------------------------------------------------
  !! 
  !! This module contains various printing routines
  !! 
  IMPLICIT NONE
  ! 
  CONTAINS
    ! 
    !-----------------------------------------------------------------------
    SUBROUTINE print_gkk(iq)
    !-----------------------------------------------------------------------
    !! 
    !! Print the |g| vertex for all n,n' and modes in meV and do average
    !! on degenerate states. 
    !!
    !-----------------------------------------------------------------------
    USE kinds,         ONLY : DP
    USE io_global,     ONLY : stdout
    USE phcom,         ONLY : nmodes
    USE epwcom,        ONLY : nbndsub
    USE elph2,         ONLY : etf, ibndmin, nkqf, xqf, nbndfst,    &
                              nkf, epf17, xkf, nkqtotf, wf, nktotf
    USE constants_epw, ONLY : ryd2mev, ryd2ev, two, zero, eps8
    USE mp,            ONLY : mp_barrier, mp_sum
    USE mp_global,     ONLY : inter_pool_comm
    USE mp_world,      ONLY : mpime
    USE io_global,     ONLY : ionode_id
    USE division,      ONLY : fkbounds
    USE poolgathering, ONLY : poolgather2
    !
    IMPLICIT NONE
    !
    INTEGER, INTENT(in) :: iq
    !! Current q-point index 
    !
    ! Local variables 
    INTEGER :: lower_bnd
    !! Lower bounds index after k or q paral
    INTEGER :: upper_bnd
    !! Upper bounds index after k or q paral
    INTEGER :: ik
    !! K-point index
    INTEGER :: ikk
    !! K-point index
    INTEGER :: ikq
    !! K+q-point index
    INTEGER :: ibnd
    !! Band index
    INTEGER :: jbnd
    !! Band index
    INTEGER :: pbnd
    !! Band index
    INTEGER :: nu
    !! Mode index
    INTEGER :: mu
    !! Mode index
    INTEGER :: n
    !! Number of modes
    INTEGER :: ierr
    !! Error status
    REAL(KIND = DP) :: xkf_all(3, nkqtotf)
    !! Collect k-point coordinate from all pools in parallel case
    REAL(KIND = DP) :: etf_all(nbndsub, nkqtotf)
    !! Collect eigenenergies from all pools in parallel case
    REAL(KIND = DP) :: wq
    !! Phonon frequency 
    REAL(KIND = DP) :: w_1
    !! Temporary phonon freq. 1
    REAL(KIND = DP) :: w_2
    !! Temporary phonon freq. 2
    REAL(KIND = DP) :: gamma
    !! Temporary electron-phonon matrix element
    REAL(KIND = DP) :: ekk
    !! Eigenenergies at k
    REAL(KIND = DP) :: ekq
    !! Eigenenergies at k+q
    REAL(KIND = DP) :: g2
    !! Temporary electron-phonon matrix element square
    REAL(KIND = DP), ALLOCATABLE :: epc(:, :, :, :)
    !! g vectex accross all pools 
    REAL(KIND = DP), ALLOCATABLE :: epc_sym(:, :, :)
    !! Temporary g-vertex for each pool 
    ! 
    ! find the bounds of k-dependent arrays in the parallel case in each pool
    CALL fkbounds(nktotf, lower_bnd, upper_bnd)
    ! 
    ALLOCATE(epc(nbndfst, nbndfst, nmodes, nktotf), STAT = ierr)
    IF (ierr /= 0) CALL errore('print_gkk', 'Error allocating epc', 1)
    ALLOCATE(epc_sym(nbndfst, nbndfst, nmodes), STAT = ierr)
    IF (ierr /= 0) CALL errore('print_gkk', 'Error allocating epc_sym', 1)
    ! 
    epc(:, :, :, :)  = zero
    epc_sym(:, :, :) = zero
    !
    ! First do the average over bands and modes for each pool
    DO ik = 1, nkf
      ikk = 2 * ik - 1
      ikq = ikk + 1
      ! 
      DO nu = 1, nmodes
        wq = wf(nu, iq)
        DO ibnd = 1, nbndfst
          DO jbnd = 1, nbndfst
            gamma = (ABS(epf17(jbnd, ibnd, nu, ik)))**two
            IF (wq > 0.d0) THEN
              gamma = gamma / (two * wq)
            ELSE
              gamma = 0.d0
            ENDIF
            gamma = DSQRT(gamma)
            ! gamma = |g| [Ry]
            epc(ibnd, jbnd, nu, ik + lower_bnd - 1) = gamma
          ENDDO ! jbnd
        ENDDO   ! ibnd        
      ENDDO ! loop on modes
      !
      ! Here we "SYMMETRIZE": actually we simply take the averages over
      ! degenerate states, it is only a convention because g is gauge-dependent!
      !
      ! first the phonons
      DO ibnd = 1, nbndfst
        DO jbnd = 1, nbndfst
          DO nu = 1, nmodes
            w_1 = wf(nu, iq)
            g2 = 0.d0
            n  = 0
            DO mu = 1, nmodes
              w_2 = wf(mu, iq)
              IF (ABS(w_2 - w_1) < eps8) THEN
                n = n + 1
                g2 = g2 + epc(ibnd, jbnd, mu, ik + lower_bnd - 1) * epc(ibnd, jbnd, mu, ik + lower_bnd - 1)
              ENDIF
            ENDDO
            g2 = g2 / FLOAT(n)
            epc_sym(ibnd, jbnd, nu) = DSQRT(g2)
          ENDDO
        ENDDO
      ENDDO
      epc(:, :, :, ik + lower_bnd - 1) = epc_sym
      ! Then the k electrons
      DO nu = 1, nmodes
        DO jbnd = 1, nbndfst
          DO ibnd = 1, nbndfst
            w_1 = etf(ibndmin - 1 + ibnd, ikk)
            g2 = 0.d0
            n  = 0
            DO pbnd = 1, nbndfst
              w_2 = etf(ibndmin - 1 + pbnd, ikk)
              IF (ABS(w_2-w_1) < eps8) THEN
                n = n + 1
                g2 = g2 + epc(pbnd, jbnd, nu, ik + lower_bnd - 1) * epc(pbnd, jbnd, nu, ik + lower_bnd - 1)
              ENDIF
            ENDDO
            g2 = g2 / FLOAT(n)
            epc_sym(jbnd, ibnd, nu) = DSQRT(g2)
          ENDDO
        ENDDO
      ENDDO
      epc(:, :, :, ik + lower_bnd - 1) = epc_sym
      !
      ! and finally the k+q electrons
      DO nu = 1, nmodes
        DO ibnd = 1, nbndfst
          DO jbnd = 1, nbndfst
            w_1 = etf(ibndmin - 1 + jbnd, ikq)
            g2 = 0.d0
            n  = 0
            DO pbnd = 1, nbndfst
              w_2 = etf(ibndmin - 1 + pbnd, ikq)
              IF (ABS(w_2 - w_1) < eps8) then
                n = n + 1
                g2 = g2 + epc(ibnd, pbnd, nu, ik + lower_bnd - 1) * epc(ibnd, pbnd, nu, ik + lower_bnd - 1)
              ENDIF
            ENDDO
            g2 = g2 / FLOAT(n)
            epc_sym(ibnd, jbnd, nu) = DSQRT(g2)
          ENDDO
        ENDDO
      ENDDO
      epc(:, :, :, ik + lower_bnd - 1) = epc_sym
      ! 
    ENDDO ! k-points
    ! 
    ! We need quantity from all the pools
    xkf_all(:, :) = zero
    etf_all(:, :) = zero
    !
#if defined(__MPI)
    !
    ! Note that poolgather2 works with the doubled grid (k and k+q)
    !
    CALL poolgather2(3,       nkqtotf, nkqf, xkf, xkf_all)
    CALL poolgather2(nbndsub, nkqtotf, nkqf, etf, etf_all)
    CALL mp_sum(epc, inter_pool_comm )
    CALL mp_barrier(inter_pool_comm)
    !
#else
    !
    xkf_all = xkf
    etf_all = etf
    !
#endif
    !
    ! Only master writes
    IF (mpime == ionode_id) THEN
      !
      WRITE(stdout, '(5x, a)') ' Electron-phonon vertex |g| (meV)'
      !
      WRITE(stdout, '(/5x, "iq = ", i7, " coord.: ", 3f12.7)') iq, xqf(:, iq)
      DO ik = 1, nktotf
        !
        ikk = 2 * ik - 1
        ikq = ikk + 1
        !
        WRITE(stdout, '(5x, "ik = ", i7, " coord.: ", 3f12.7)') ik, xkf_all(:, ikk)
        WRITE(stdout, '(5x, a)') ' ibnd     jbnd     imode   enk[eV]    enk+q[eV]  omega(q)[meV]   |g|[meV]'
        WRITE(stdout, '(5x, a)') REPEAT('-',78)
        !
        DO ibnd = 1, nbndfst
          ekk = etf_all(ibndmin - 1 + ibnd, ikk) 
          DO jbnd = 1, nbndfst
            ekq = etf_all(ibndmin - 1 + jbnd, ikq) 
            DO nu = 1, nmodes
              WRITE(stdout, '(3i9, 3f12.4, 1e20.10)') ibndmin - 1 + ibnd, ibndmin - 1 + jbnd, & 
                   nu, ryd2ev * ekk, ryd2ev * ekq, ryd2mev * wf(nu, iq), ryd2mev * epc(ibnd, jbnd, nu, ik)
            ENDDO
          ENDDO  
          !
        ENDDO
        WRITE(stdout, '(5x, a/)') REPEAT('-',78)
        !
      ENDDO
    ENDIF ! master node
    ! 
    DEALLOCATE(epc, STAT = ierr)
    IF (ierr /= 0) CALL errore('print_gkk', 'Error deallocating epc', 1)
    DEALLOCATE(epc_sym, STAT = ierr)
    IF (ierr /= 0) CALL errore('print_gkk', 'Error deallocating epc_sym', 1)
    !
    !-----------------------------------------------------------------------
    END SUBROUTINE print_gkk
    !-----------------------------------------------------------------------
    !
    !-----------------------------------------------------------------------
    SUBROUTINE print_mob_sym(f_out, s_BZtoIBZ, BZtoIBZ_mat, vkk_all, etf_all, wkf_all, ef0, max_mob)
    !-----------------------------------------------------------------------
    !!
    !! This routine prints the mobility using k-point symmetry.
    !!
    USE kinds,         ONLY : DP
    USE epwcom,        ONLY : ncarrier, nstemp, nkf1, nkf2, nkf3, assume_metal
    USE elph2,         ONLY : nbndfst, transp_temp, nktotf 
    USE constants_epw, ONLY : zero, two, pi, kelvin2eV, ryd2ev, eps10, &
                              electron_SI, bohr2ang, ang2cm, hbarJ
    USE symm_base,     ONLY : nrot
    USE mp,            ONLY : mp_sum
    USE kinds_epw,     ONLY : SIK2
    !
    IMPLICIT NONE
    !
    INTEGER(SIK2), INTENT(in) :: s_BZtoIBZ(nkf1 * nkf2 * nkf3)
    !! Corresponding symmetry matrix
    INTEGER, INTENT(in) :: BZtoIBZ_mat(nrot, nktotf)
    !! For a given k-point from the IBZ, given the index of all k from full BZ
    REAL(KIND = DP), INTENT(in) :: f_out(3, nbndfst, nktotf, nstemp)  
    !! occupations factor produced by SERTA or IBTE
    REAL(KIND = DP), INTENT(in) :: vkk_all(3, nbndfst, nktotf)
    !! Velocity
    REAL(KIND = DP), INTENT(in) :: etf_all(nbndfst, nktotf)
    !! Eigenenergies of k
    REAL(KIND = DP), INTENT(in) :: wkf_all(nktotf)
    !! Weight of k
    REAL(KIND = DP), INTENT(in) :: ef0(nstemp)
    !! The Fermi level 
    REAL(KIND = DP), INTENT(INOUT), OPTIONAL :: max_mob(nstemp)
    !! Maximum mobility
    ! 
    ! Local variables
    INTEGER :: itemp
    !! temperature index
    INTEGER :: ik 
    !! k-point index
    INTEGER :: ibnd
    !! band index
    REAL(KIND = DP) :: etemp
    !! Temperature in Ry (this includes division by kb)
    REAL(KIND = DP) :: sigma(3, 3)
    !! Electrical conductivity
    REAL(KIND = DP) :: ekk
    !! Energy relative to Fermi level: $$\varepsilon_{n\mathbf{k}}-\varepsilon_F$$ 
    REAL(KIND = DP) :: carrier_density
    !! Carrier density [nb of carrier per unit cell]
    REAL(KIND = DP) :: fnk
    !! Fermi-Dirac occupation function
    REAL(KIND = DP), EXTERNAL :: wgauss
    !! Compute the approximate theta function. Here computes Fermi-Dirac 
    REAL(KIND = DP), EXTERNAL :: w0gauss
    !! The derivative of wgauss:  an approximation to the delta function 
    REAL(KIND = DP) :: fi_check(3)
    !! Sum rule on population
    !
    IF (PRESENT(max_mob)) THEN
      max_mob(:) = zero
    ENDIF
    ! 
    ! Hole
    IF (ncarrier < -1E5 .AND. .NOT. assume_metal) THEN
      CALL prtheader(-1)
      DO itemp = 1, nstemp
        carrier_density = 0.0
        etemp = transp_temp(itemp)
        sigma(:, :) = zero
        fi_check(:) = zero
        DO ik = 1,  nktotf
          DO ibnd = 1, nbndfst
            IF (etf_all(ibnd, ik) < ef0(itemp)) THEN
              CALL compute_sigma_sym(f_out(:, :, :, itemp), s_BZtoIBZ(:), BZtoIBZ_mat(:, :), vkk_all(:, :, :), sigma(:, :), &
                fi_check(:), ibnd, ik)
              !  energy at k (relative to Ef)
              ekk = etf_all(ibnd, ik) - ef0(itemp)
              fnk = wgauss(-ekk / etemp, -99)
              ! The wkf(ikk) already include a factor 2
              carrier_density = carrier_density + wkf_all(ik) * (1.0d0 - fnk)
            ENDIF ! if below Fermi level
          ENDDO ! ibnd
        ENDDO ! ik
        ! 
        ! Print the resulting mobility
        CALL prtmob(sigma(:, :), carrier_density, fi_check(:), ef0(itemp), etemp, max_mob(itemp))
      ENDDO ! temp
    ENDIF
    ! 
    ! Now electron mobility
    IF (ncarrier > 1E5 .AND. .NOT. assume_metal) THEN
      CALL prtheader(1)
      DO itemp = 1, nstemp
        carrier_density = 0.0
        etemp = transp_temp(itemp)
        sigma(:, :) = zero
        fi_check(:) = zero
        DO ik = 1,  nktotf
          DO ibnd = 1, nbndfst
            IF (etf_all(ibnd, ik) > ef0(itemp)) THEN
              CALL compute_sigma_sym(f_out(:, :, :, itemp), s_BZtoIBZ(:), BZtoIBZ_mat(:, :), vkk_all(:, :, :), sigma(:, :), &
                fi_check(:), ibnd, ik)
              !  energy at k (relative to Ef)
              ekk = etf_all(ibnd, ik) - ef0(itemp)
              fnk = wgauss(-ekk / etemp, -99)
              ! The wkf(ikk) already include a factor 2
              carrier_density = carrier_density + wkf_all(ik) * fnk
            ENDIF ! if below Fermi level
          ENDDO ! ibnd
        ENDDO ! ik
        ! Print the resulting mobility
        CALL prtmob(sigma(:, :), carrier_density, fi_check(:), ef0(itemp), etemp, max_mob(itemp))
      ENDDO ! temp
    ENDIF
    !
    ! do metals now
    If (assume_metal) THEN
      CALL prtheader()
      DO itemp = 1, nstemp
        carrier_density = 0.0
        etemp = transp_temp(itemp)
        sigma(:, :) = zero
        fi_check(:) = zero
        DO ik = 1,  nktotf
          DO ibnd = 1, nbndfst
            ! just sum on all bands for metals
            CALL compute_sigma_sym(f_out(:, :, :, itemp), s_BZtoIBZ(:), BZtoIBZ_mat(:, :), vkk_all(:, :, :), sigma(:, :), &
              fi_check(:), ibnd, ik)
            !  energy at k (relative to Ef)
            ekk = etf_all(ibnd, ik) - ef0(itemp)
            fnk = wgauss(-ekk / etemp, -99)
            ! The wkf(ikk) already include a factor 2
            carrier_density = carrier_density + wkf_all(ik) * fnk
          ENDDO ! ibnd
        ENDDO ! ik
        ! Print the resulting mobility
        CALL prtmob(sigma(:, :), carrier_density, fi_check(:), ef0(itemp), etemp, max_mob(itemp))
      ENDDO ! itemp      
    ENDIF
    !
    !-----------------------------------------------------------------------
    END SUBROUTINE print_mob_sym
    !-----------------------------------------------------------------------
    !
    !-----------------------------------------------------------------------
    SUBROUTINE compute_sigma_sym(f_out, s_BZtoIBZ, BZtoIBZ_mat, vkk_all, &
                    sigma, fi_check, ibnd, ik)
    !-----------------------------------------------------------------------
    !!
    !!  Computes one element of the sigma tensor when using symmetries.
    !!
    !----------------------------------------------------------------------
    USE kinds,         ONLY : DP
    USE cell_base,     ONLY : at, bg
    USE epwcom,        ONLY : nkf1, nkf2, nkf3
    USE elph2,         ONLY : nbndfst, nktotf 
    USE symm_base,     ONLY : s, nrot
    USE noncollin_module, ONLY : noncolin
    USE kinds_epw,     ONLY : SIK2
    !
    IMPLICIT NONE
    !
    INTEGER(SIK2), INTENT(IN) :: s_BZtoIBZ(nkf1 * nkf2 * nkf3)
    !! Corresponding symmetry matrix
    INTEGER, INTENT(IN) :: BZtoIBZ_mat(nrot, nktotf)
    !! For a given k-point from the IBZ, given the index of all k from full BZ
    INTEGER, INTENT(IN) :: ik 
    !! k-point index
    INTEGER, INTENT(IN) :: ibnd
    !! band index
    REAL(KIND = DP), INTENT(in) :: f_out(3, nbndfst, nktotf)  
    !! Occupation function produced by SERTA or IBTE
    REAL(KIND = DP), INTENT(in) :: vkk_all(3, nbndfst, nktotf)
    !! Velocity
    REAL(KIND = DP), INTENT(INOUT) :: sigma(3, 3)
    !! Electrical conductivity
    REAL(KIND = DP), INTENT(INOUT) :: fi_check(3)
    !! Sum rule on population
    !
    ! Local variables
    !
    INTEGER :: nb 
    !! Number of points equivalent by sym from BZ to IBTZ
    INTEGER :: ikbz
    !! Index of full BZ points
    INTEGER :: i,j
    !! Cartesian index
    REAL(KIND = DP) :: vk_cart(3)
    !! veloctiy in cartesian coordinate
    REAL(KIND = DP) :: fi_cart(3)
    !! Cartesian Fi_all 
    REAL(KIND = DP) :: fi_rot(3)
    !! Rotated Fi_all by the symmetry operation
    REAL(KIND = DP) :: v_rot(3)
    !! Rotated velocity by the symmetry operation
    REAL(KIND = DP) :: sa(3, 3)
    !! Symmetry matrix in crystal
    REAL(KIND = DP) :: sb(3, 3)
    !! Symmetry matrix (intermediate step)
    REAL(KIND = DP) :: sr(3, 3)
    !! Symmetry matrix in cartesian coordinate 
    REAL(KIND = DP) :: sfac
    !! Spin factor
    IF (noncolin) THEN
      sfac = 1.0
    ELSE
      sfac = 2.0
    ENDIF
    vk_cart(:) = vkk_all(:, ibnd, ik)
    fi_cart(:) = f_out(:, ibnd, ik)
    !
    ! Loop on the point equivalent by symmetry in the full BZ
    DO nb = 1, nrot
      IF (BZtoIBZ_mat(nb, ik) > 0) THEN 
        ikbz = BZtoIBZ_mat(nb, ik)
        ! 
        ! Transform the symmetry matrix from Crystal to cartesian
        sa(:, :) = DBLE(s(:, :, s_BZtoIBZ(ikbz)))
        sb       = MATMUL(bg, sa)
        sr(:, :) = MATMUL(at, TRANSPOSE(sb))
        sr       = TRANSPOSE(sr) 
        !
        CALL DGEMV('n', 3, 3, 1.d0, sr, 3, vk_cart(:), 1 ,0.d0 , v_rot(:), 1)
        CALL DGEMV('n', 3, 3, 1.d0, sr, 3, fi_cart(:), 1 ,0.d0 , fi_rot(:), 1)
        !
        DO j = 1, 3
          DO i = 1, 3
            ! The factor two in the weight at the end is to
            ! account for spin
            sigma(i, j) = sigma(i, j) - (v_rot(j) * fi_rot(i)) * sfac / (nkf1 * nkf2 * nkf3)
          ENDDO
        ENDDO
        !
        fi_check(:) = fi_check(:) + fi_rot(:) * sfac / (nkf1 * nkf2 * nkf3)
      ENDIF ! BZ 
    ENDDO ! ikb
    ! 
    !-----------------------------------------------------------------------
    END SUBROUTINE compute_sigma_sym
    !-----------------------------------------------------------------------
    ! 
    !-----------------------------------------------------------------------
    SUBROUTINE print_mob(f_out, vkk_all, etf_all, wkf_all, ef0, max_mob) 
    !-----------------------------------------------------------------------
    !!
    !! This routine prints the mobility without k-point symmetry
    !!
    !-----------------------------------------------------------------------
    USE kinds,         ONLY : DP
    USE epwcom,        ONLY : ncarrier, nstemp, nkf1, nkf2, nkf3, assume_metal
    USE elph2,         ONLY : nbndfst, transp_temp, nktotf 
    USE constants_epw, ONLY : zero, two, pi, kelvin2eV, ryd2ev, eps10, &
                              electron_SI, bohr2ang, ang2cm, hbarJ
    USE noncollin_module, ONLY : noncolin
    USE mp,            ONLY : mp_sum
    !
    IMPLICIT NONE
    !
    REAL(KIND = DP), INTENT(in) :: f_out(3, nbndfst, nktotf, nstemp)  
    !! Occupation function produced by SERTA or IBTE
    REAL(KIND = DP), INTENT(in) :: vkk_all(3, nbndfst, nktotf)
    !! Velocity
    REAL(KIND = DP), INTENT(in) :: etf_all(nbndfst, nktotf)
    !! Eigenenergies of k
    REAL(KIND = DP), INTENT(in) :: wkf_all(nktotf)
    !! Weight of k
    REAL(KIND = DP), INTENT(in) :: ef0(nstemp)
    !! The Fermi level 
    REAL(KIND = DP), INTENT(INOUT), OPTIONAL :: max_mob(nstemp)
    !! The maximum mobility computed by thr prtmob routine.
    ! 
    ! Local variables
    INTEGER :: itemp
    !! temperature index
    INTEGER :: ik 
    !! k-point index
    INTEGER :: ibnd
    !! band index
    INTEGER :: i, j
    !! Cartesian index
    REAL(KIND = DP) :: etemp
    !! Temperature in Ry (this includes division by kb)
    REAL(KIND = DP) :: sigma(3, 3)
    !! Electrical conductivity
    REAL(KIND = DP) :: ekk
    !! Energy relative to Fermi level: $$\varepsilon_{n\mathbf{k}}-\varepsilon_F$$ 
    REAL(KIND = DP) :: carrier_density
    !! Carrier density [nb of carrier per unit cell]
    REAL(KIND = DP) :: fnk
    !! Fermi-Dirac occupation function
    REAL(KIND = DP) :: Fi_check(3)
    !! Sum rule on population
    REAL(KIND = DP), EXTERNAL :: wgauss
    !! Compute the approximate theta function. Here computes Fermi-Dirac 
    REAL(KIND = DP), EXTERNAL :: w0gauss
    !! The derivative of wgauss:  an approximation to the delta function 
    REAL(KIND = DP) :: sfac
    !! Spin factor
    !
    IF (PRESENT(max_mob)) THEN
      max_mob(:) = zero
    ENDIF
    ! Hole
    IF (ncarrier < -1E5 .AND. .NOT. assume_metal) THEN
      ! 
      CALL prtheader(-1)
      DO itemp = 1, nstemp
        carrier_density = 0.0
        etemp = transp_temp(itemp)
        sigma(:, :) = zero
        fi_check(:) = zero
        DO ik = 1,  nktotf
          DO ibnd = 1, nbndfst
            IF (etf_all(ibnd, ik) < ef0(itemp)) THEN
              CALL compute_sigma(f_out(:, :, :, itemp), vkk_all(:, :, :), wkf_all(:) , sigma(:, :), fi_check(:), ibnd, ik)
              !  energy at k (relative to Ef)
              ekk = etf_all(ibnd, ik) - ef0(itemp)
              fnk = wgauss(-ekk / etemp, -99)
              ! The wkf(ikk) already include a factor 2
              carrier_density = carrier_density + wkf_all(ik) * (1.0d0 - fnk)
            ENDIF ! if below Fermi level
          ENDDO ! ibnd
        ENDDO ! ik
        CALL prtmob(sigma(:, :), carrier_density, fi_check(:), ef0(itemp), etemp, max_mob(itemp)) 
      ENDDO ! itemp      
      ! 
    ENDIF
    ! 
    ! Now electron mobility
    IF (ncarrier > 1E5 .AND. .NOT. assume_metal) THEN
      CALL prtheader(+1)
      DO itemp = 1, nstemp
        carrier_density = 0.0
        etemp = transp_temp(itemp)
        sigma(:, :) = zero
        fi_check(:) = zero
        DO ik = 1,  nktotf
          DO ibnd = 1, nbndfst
            IF (etf_all(ibnd, ik) > ef0(itemp)) THEN
              CALL compute_sigma(f_out(:, :, :, itemp), vkk_all(:, :, :), wkf_all(:) , sigma(:, :), fi_check(:), ibnd, ik)
              !  energy at k (relative to Ef)
              ekk = etf_all(ibnd, ik) - ef0(itemp)
              fnk = wgauss(-ekk / etemp, -99)
              ! The wkf(ikk) already include a factor 2
              carrier_density = carrier_density + wkf_all(ik) * fnk
            ENDIF ! if below Fermi level
          ENDDO ! ibnd
        ENDDO ! ik
        CALL prtmob(sigma(:, :), carrier_density, fi_check(:), ef0(itemp), etemp, max_mob(itemp)) 
      ENDDO
      ! 
    ENDIF
    IF (assume_metal) THEN
      CALL prtheader()
      DO itemp = 1, nstemp
        carrier_density = 0.0
        etemp = transp_temp(itemp)
        sigma(:, :) = zero
        fi_check(:) = zero
        DO ik = 1,  nktotf
          DO ibnd = 1, nbndfst
            ! sum on all bands for metals
            call compute_sigma(f_out(:, :, :, itemp), vkk_all(:, :, :), wkf_all(:) , sigma(:, :), fi_check(:), ibnd, ik)
            !  energy at k (relative to Ef)
            ekk = etf_all(ibnd, ik) - ef0(itemp)
            fnk = wgauss(-ekk / etemp, -99)
            ! The wkf(ikk) already include a factor 2
            carrier_density = carrier_density + wkf_all(ik) * fnk
          ENDDO ! ibnd
        ENDDO ! ik
      ENDDO
    ENDIF
    !-----------------------------------------------------------------------
    END SUBROUTINE print_mob
    !-----------------------------------------------------------------------
    !
    !-----------------------------------------------------------------------
    SUBROUTINE compute_sigma(f_out, vkk_all, wkf_all, sigma, fi_check, ibnd, ik)
    !-----------------------------------------------------------------------
    USE kinds,         ONLY : DP
    USE epwcom,        ONLY : nkf1, nkf2, nkf3
    USE elph2,         ONLY : nbndfst, nktotf 
    USE noncollin_module, ONLY : noncolin
    !
    IMPLICIT NONE
    !
    INTEGER, INTENT(IN) :: ik 
    !! k-point index
    INTEGER, INTENT(IN) :: ibnd
    !! band index
    REAL(KIND = DP), INTENT(in) :: f_out(3, nbndfst, nktotf)  
    !! Occupation function produced by SERTA or IBTE
    REAL(KIND = DP), INTENT(INOUT) :: sigma(3, 3)
    !! Electrical conductivity
    REAL(KIND = DP), INTENT(INOUT) :: fi_check(3)
    !! Sum rule on population
    REAL(KIND = DP), INTENT(in) :: vkk_all(3, nbndfst, nktotf)
    !! Velocity
    REAL(KIND = DP), INTENT(in) :: wkf_all(nktotf)
    !! Weight of k
    !
    ! Local variables
    !
    INTEGER :: i, j
    !! Dimension loop indices
    REAL(KIND = DP) :: sfac
    !! Spin factor
    IF (noncolin) THEN
      sfac = 1.0
    ELSE
      sfac = 2.0
    ENDIF

    DO j = 1, 3
      DO i = 1, 3
        sigma(i, j) = sigma(i, j) - vkk_all(j, ibnd, ik) * f_out(i, ibnd, ik) * wkf_all(ik)
      ENDDO
    ENDDO
    fi_check(:) = fi_check(:) + f_out(:, ibnd, ik) * sfac / (nkf1 * nkf2 * nkf3)
    !-----------------------------------------------------------------------
    END SUBROUTINE compute_sigma
    !-----------------------------------------------------------------------
    !-----------------------------------------------------------------------
    SUBROUTINE prtmob(sigma, carrier_density, Fi_check, ef0, etemp, max_mob) 
    !-----------------------------------------------------------------------
    !! 
    !! This routine print the mobility (or conducrtivity for metals) in a 
    !! nice format and in proper units.
    !! 
    USE kinds,         ONLY : DP
    USE epwcom,        ONLY : assume_metal
    USE io_global,     ONLY : stdout
    USE cell_base,     ONLY : omega
    USE constants_epw, ONLY : zero, kelvin2eV, ryd2ev, eps80, &
                              electron_SI, bohr2ang, ang2cm, hbarJ
    !
    IMPLICIT NONE
    !
    REAL(KIND = DP), INTENT(in) :: sigma(3, 3)
    !! Conductivity tensor
    REAL(KIND = DP), INTENT(in) :: carrier_density
    !! Carrier density in a.u.
    REAL(KIND = DP), INTENT(in) :: Fi_check(3)
    !! Integrated population vector
    REAL(KIND = DP), INTENT(in) :: ef0
    !! Fermi-level 
    REAL(KIND = DP), INTENT(in) :: etemp
    !! Temperature in Ry (this includes division by kb)
    REAL(KIND = DP), INTENT(inout), OPTIONAL :: max_mob
    !! Maximum error for all temperature
    ! 
    ! Local variables
    REAL(KIND = DP) :: mobility(3, 3)
    !! mobility 
    REAL(KIND = DP) :: inv_cell
    !! Inverse of the volume in [Bohr^{-3}]
    REAL(KIND = DP) :: nden
    !! Carrier density in cm^-3
    ! 
    inv_cell = 1.0d0 / omega
    ! carrier_density in cm^-1
    nden = carrier_density * inv_cell * (bohr2ang * ang2cm)**(-3)
    mobility(:, :) = (sigma(:, :) * electron_SI ** 2 * inv_cell) / (hbarJ * bohr2ang * ang2cm)
    IF (.NOT. assume_metal) THEN
      ! for insulators print mobility so just divide by carrier density
      IF (ABS(nden) < eps80) CALL errore('prtmob', 'The carrier density is 0', 1)
      mobility(:, :) = mobility(:, :) / (electron_SI * carrier_density * inv_cell) * (bohr2ang * ang2cm) ** 3
      WRITE(stdout, '(5x, 1f8.3, 1f9.4, 1E14.5, 1E14.5, 3E16.6)') etemp * ryd2ev / kelvin2eV, ef0 * ryd2ev, &
           nden, SUM(Fi_check(:)), mobility(1, 1), mobility(1, 2), mobility(1, 3)
      WRITE(stdout, '(50x, 3E16.6)') mobility(2, 1), mobility(2, 2), mobility(2, 3) 
      WRITE(stdout, '(50x, 3E16.6)') mobility(3, 1), mobility(3, 2), mobility(3, 3)
    ELSE
      WRITE(stdout, '(5x, 1f8.3, 1f9.4, 1E14.5, 3E16.6)') etemp * ryd2ev / kelvin2eV, ef0 * ryd2ev, &
           SUM(Fi_check(:)), mobility(1, 1), mobility(1, 2), mobility(1, 3)
      WRITE(stdout, '(37x, 3E16.6)') mobility(2, 1), mobility(2, 2), mobility(2, 3) 
      WRITE(stdout, '(37x, 3E16.6)') mobility(3, 1), mobility(3, 2), mobility(3, 3)
    ENDIF
    IF (PRESENT(max_mob)) THEN
      max_mob = MAXVAL(mobility(:,:))
    ENDIF
    ! 
    !-----------------------------------------------------------------------
    END SUBROUTINE prtmob
    !-----------------------------------------------------------------------
    !-----------------------------------------------------------------------
    SUBROUTINE prtheader(cal_type)
    !-----------------------------------------------------------------------
    !! 
    !! This routine print a header for mobility calculation
    !! 
    USE io_global,     ONLY : stdout
    USE epwcom,        ONLY : assume_metal
    !
    IMPLICIT NONE
    !
    INTEGER, INTENT(IN), OPTIONAL :: cal_type
    !! +1 means electron and -1 means hole,
    !! If assume_metal is True then nothing is considered
    WRITE(stdout, '(/5x, a)') REPEAT('=',93)
    IF (.NOT. assume_metal) THEN
      IF (.NOT. PRESENT(cal_type)) THEN
        CALL errore("prtheader", "DEV ERROR: Must specify cal_type", 1)
      ENDIF
      IF (cal_type == -1) THEN 
        WRITE(stdout, '(5x, "  Temp     Fermi   Hole density  Population SR                  Hole mobility ")')
        WRITE(stdout, '(5x, "   [K]      [eV]     [cm^-3]      [h per cell]                    [cm^2/Vs]")')
      ELSEIF (cal_type == 1) THEN
        WRITE(stdout, '(5x, "  Temp     Fermi   Elec density  Population SR                  Elec mobility ")')
        WRITE(stdout, '(5x, "   [K]      [eV]     [cm^-3]      [e per cell]                    [cm^2/Vs]")')
      ENDIF
    ELSE
      WRITE(stdout, '(5x, "  Temp     Fermi    Population SR                  Conductivity ")')
      WRITE(stdout, '(5x, "   [K]      [eV]  [carriers per cell]              [Ohm.cm]^-1 ")')
    ENDIF
    WRITE(stdout, '(5x, a/)') REPEAT('=',93)
    !-----------------------------------------------------------------------
    END SUBROUTINE prtheader
    !-----------------------------------------------------------------------
    ! 
    !-----------------------------------------------------------------------
    SUBROUTINE print_clock_epw
    !-----------------------------------------------------------------------
    !!  
    !! Adapted from the code PH/print_clock_ph - Quantum-ESPRESSO group          
    !!  
    USE io_global,     ONLY : stdout
    USE uspp,          ONLY : nlcc_any
    !  
    IMPLICIT NONE
    !
    WRITE(stdout, '(5x)')
    WRITE(stdout, '(5x, a)') 'Unfolding on the coarse grid'
    CALL print_clock('dvanqq2')
    CALL print_clock('elphon_wrap')
    WRITE(stdout, '(5x)')
    CALL print_clock('ELPHWAN')
    WRITE(stdout, '(5x, a)') 'INITIALIZATION: '
    CALL print_clock('epq_init')
    WRITE(stdout, '(5x)')
    CALL print_clock('epq_init')
    IF (nlcc_any) CALL print_clock('set_drhoc')
    CALL print_clock('init_vloc')
    CALL print_clock('init_us_1')
    CALL print_clock('newd')
    CALL print_clock('dvanqq2')
    CALL print_clock('drho')
    WRITE(stdout, '(5x)')
    WRITE(stdout, '(5x)')
    !
    ! Electron-Phonon interpolation 
    !
    WRITE(stdout, '(5x)')
    WRITE(stdout, '(5x, a)') 'Electron-Phonon interpolation'   
    CALL print_clock('ephwann')
    CALL print_clock('ep-interp')
    CALL print_clock('PH SELF-ENERGY')
    CALL print_clock('ABS SPECTRA')
    CALL print_clock('crys_cart')
    WRITE(stdout, '(5x)')
    CALL print_clock('load data')
    CALL print_clock('Ham: step 1')
    CALL print_clock('Ham: step 2')
    CALL print_clock('Ham: step 3')
    CALL print_clock('Ham: step 4')
    CALL print_clock('ep: step 1')
    CALL print_clock('ep: step 2')
    CALL print_clock('ep: step 3')
    CALL print_clock('ep: step 4')
    CALL print_clock('DynW2B')
    CALL print_clock('HamW2B')
    CALL print_clock('ephW2Bp')
    CALL print_clock('ephW2B')
    CALL print_clock('print_ibte')
    CALL print_clock('vmewan2bloch')
    CALL print_clock('vmewan2blochp')
    CALL print_clock('ephW2Bp1')
    CALL print_clock('ephW2Bp2')
    CALL print_clock('kpoint_paral') 
    !
    ! Eliashberg equations
    WRITE(stdout, '(5x)')
    CALL print_clock('ELIASHBERG')
    !
    WRITE(stdout, '(5x)')
    WRITE(stdout, '(5x, a)') 'Total program execution'
    CALL print_clock('EPW') 
    !
    !-----------------------------------------------------------------------
    END SUBROUTINE print_clock_epw
    !-----------------------------------------------------------------------
    ! 
  !-------------------------------------------------------------------------
  END MODULE printing
  !-------------------------------------------------------------------------
