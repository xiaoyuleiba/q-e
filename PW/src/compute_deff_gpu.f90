!
! Copyright (C) 2009-2010 Quantum ESPRESSO group
! This file is distributed under the terms of the
! GNU General Public License. See the file `License'
! in the root directory of the present distribution,
! or http://www.gnu.org/copyleft/gpl.txt .
!
!
!-------------------------------------------------------------------------
SUBROUTINE compute_deff_gpu( deff, et )
  !-----------------------------------------------------------------------
  !! This routine computes the effective value of the D-eS coefficients
  !! which appear often in many expressions in the US or PAW case. 
  !! This routine is for the collinear case.
  !
  USE kinds,       ONLY: DP
  USE ions_base,   ONLY: nat
  USE uspp,        ONLY: okvan, deeq, qq_at
  USE uspp_param,  ONLY: nhm
  USE lsda_mod,    ONLY: current_spin
  !
  IMPLICIT NONE
  !
  REAL(DP), INTENT(IN) :: et
  !! The eigenvalues of the hamiltonian
  COMPLEX(DP), INTENT(OUT) :: deff(nhm,nhm,nat)
  !! Effective values of the D-eS coefficients
  !
  ! ... local variables
  !
  INTEGER :: nt, na, is, i, j
  !
  !$acc kernels present_or_copyout(deff)
  !
  IF (.NOT. okvan) THEN
     !
     deff(:,:,:) = CMPLX(deeq(:,:,:,current_spin))
     !
  ELSE
     !
     deff(:,:,:) = CMPLX(deeq(:,:,:,current_spin) - et*qq_at(:,:,:))
     !
  ENDIF
  !
  !$acc end kernels
  !
  RETURN
  !
END SUBROUTINE compute_deff_gpu
!
!
!---------------------------------------------------------------------------
SUBROUTINE compute_deff_nc_gpu( deff, et )
  !-------------------------------------------------------------------------
  !! This routine computes the effective value of the D-eS coefficients
  !! which appears often in many expressions. This routine is for the
  !! noncollinear case.
  !
  USE kinds,            ONLY: DP
  USE ions_base,        ONLY: nsp, nat, ityp
  USE noncollin_module, ONLY: noncolin, npol, lspinorb
  USE uspp,             ONLY: okvan, deeq_nc, qq_so_d, qq_at
  USE uspp_param,       ONLY: nhm
  USE lsda_mod,         ONLY: nspin
  !
  IMPLICIT NONE
  !
  REAL(DP), INTENT(IN) :: et
  !! The eigenvalues of the hamiltonian
  COMPLEX(DP), INTENT(OUT) :: deff(nhm,nhm,nat,nspin) 
  !! Effective values of the D-eS coefficients
  !
  ! ... local variables
  !
  INTEGER :: nt, na, is, ijs, i, j, ias
  INTEGER :: nt_v(nat), na_v(nat)
  !
  !$acc data present_or_copyout( deff )
  !
  !$acc kernels
  deff(:,:,:,:) = deeq_nc(:,:,:,:)
  !$acc end kernels
  !
  IF (okvan) then
    !
    ! ... set up index arrays to fill 'deff' in on gpu
    i = 0
    DO nt = 1, nsp
      DO na = 1, nat
        IF ( ityp(na)/=nt ) CYCLE
        i = i + 1
        nt_v(i) = nt
        na_v(i) = na
      ENDDO
    ENDDO
    !
    !$acc data copyin( nt_v, na_v )
    !
    IF (lspinorb) THEN
      !
      !$acc parallel loop collapse(3)
      DO ias = 1, nat
        DO i = 1, nhm
          DO j = 1, nhm
            na = na_v(ias)
            nt = nt_v(ias)
            deff(i,j,na,:) = deeq_nc(i,j,na,:) - et*qq_so_d(i,j,:,nt)
          ENDDO
        ENDDO
      ENDDO
      !
    ELSE
      !
      !$acc parallel loop collapse(3)
      DO ias = 1, nat
        DO i = 1, nhm
          DO j = 1, nhm
            na = na_v(ias)
            !$acc loop seq
            DO is = 1, npol
              ijs = (is-1)*npol + is
              deff(i,j,na,ijs) = deeq_nc(i,j,na,ijs) - CMPLX(et*qq_at(i,j,na))
            ENDDO
          ENDDO
        ENDDO
      ENDDO
      !
    ENDIF
    !
    !$acc end data
    !
  ENDIF  
  !
  !$acc end data
  !
  RETURN
  !
END SUBROUTINE compute_deff_nc_gpu
