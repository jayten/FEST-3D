module boundary_state_reconstruction
  use utils,                only: dmsg
!  use grid,                 only: imx, jmx, kmx
  use global_vars,          only: imx
  use global_vars,          only: jmx
  use global_vars,          only: kmx

  use global_vars,          only: qp
  use global_vars,          only: n_var
  use global_vars,          only: ilimiter_switch
  use global_vars,          only: PB_switch

  use face_interpolant,     only: x_qp_left, x_qp_right
  use face_interpolant,     only: y_qp_left, y_qp_right
  use face_interpolant,     only: z_qp_left, z_qp_right
  use boundary_conditions,  only: bc_imn, bc_imx
  use boundary_conditions,  only: bc_jmn, bc_jmx
  use boundary_conditions,  only: bc_kmn, bc_kmx
  use boundary_conditions,  only: BC_INTERFACE

  implicit none
  private

  integer :: ppm_flag=0
  public :: reconstruct_boundary_state

  contains

    subroutine reconstruct_boundary_state(interpolant)

      implicit none
      character(len=*), intent(in)  :: interpolant
      call dmsg(1,'boundary_state_recons', 'recons_boundary_state')
      if (interpolant == 'ppm') ppm_flag=1
      if(interpolant /='none')then
        if(bc_imn(1,1) /= BC_INTERFACE)then
          call dmsg(1,'bndry_state_recons', 'recons_bndry_state', 'imin')
          call reconstruct_imin()
        end if
        if(bc_imx(1,1) /= BC_INTERFACE)then
          call dmsg(1,'bndry_state_recons', 'recons_bndry_state', 'imax')
          call reconstruct_imax()
        end if
        if(bc_jmn(1,1) /= BC_INTERFACE)then
          call dmsg(1,'bndry_state_recons', 'recons_bndry_state', 'jmin')
          call reconstruct_jmin()
        end if
        if(bc_jmx(1,1) /= BC_INTERFACE)then
          call dmsg(1,'bndry_state_recons', 'recons_bndry_state', 'jmax')
          call reconstruct_jmax()
        end if
        if(bc_kmn(1,1) /= BC_INTERFACE)then
          call dmsg(1,'bndry_state_recons', 'recons_bndry_state', 'kmin')
          call reconstruct_kmin()
        end if
        if(bc_kmx(1,1) /= BC_INTERFACE)then
        call dmsg(1,'bndry_state_recons', 'recons_bndry_state', 'kmax')
          call reconstruct_kmax()
        end if
      end if

    end subroutine reconstruct_boundary_state


    subroutine reconstruct_imin()

      implicit none
      integer :: i, j, k, l
      real :: psi1, psi2, fd, bd, r
      real :: kappa, phi

      phi = 1.0
      kappa = -1.0

      do l = 1, n_var
       do k = 1, kmx - 1
        do j = 1, jmx - 1
         do i = 1, 1 
          ! right face of first ghost cell
          x_qp_left(i, j, k, l) = qp(i-1, j, k, l)!0.5 * (qp(i-1, j, k, l) + qp(i, j, k, l))

          ! reconstruct first cell faces for ppm scheme
          if (ppm_flag==1) then

            fd = qp(i+1, j, k, l) - qp(i  , j, k, l)
            bd = qp(i  , j, k, l) - qp(i-1, j, k, l)

            r = fd / bd
            psi1 = max(0., min(2*r, (2 + r)/3., 2.))
            psi1 = (1 - (1 - psi1)*ilimiter_switch )
            r = bd / fd
            psi2 = max(0., min(2*r, (2 + r)/3., 2.))
            psi2 = (1 - (1 - psi2)*ilimiter_switch )

            ! right state of firsrt interior cell
            x_qp_left(i+1, j, k, l) = qp(i, j, k, l) + 0.25*phi* &
                (((1.-kappa) * psi1 * bd) + ((1.+kappa) * psi2 * fd))

            ! left face of first interior cell
            x_qp_right(i, j, k, l) = qp(i, j, k, l) - 0.25*phi* &
                (((1.+kappa) * psi1 * bd) + ((1.-kappa) * psi2 * fd))
            
         end if
         end do
        end do
       end do
      end do

    end subroutine reconstruct_imin


    subroutine reconstruct_imax()

      implicit none
      integer :: i, j, k, l
      real :: psi1, psi2, fd, bd, r
      real :: kappa, phi

      phi = 1.0
      kappa = -1.0

      do l = 1, n_var
       do k = 1, kmx - 1
        do j = 1, jmx - 1
         do i = imx-1, imx-1 
          ! first ghost cell imx left face.
          x_qp_right(i+1, j, k, l) = qp(i+1, j, k, l) 
                                    !0.5 * (qp(i+1, j, k, l) + qp(i, j, k, l))

          if (ppm_flag==1) then
            fd = qp(i+1, j, k, l) - qp(i  , j, k, l)
            bd = qp(i  , j, k, l) - qp(i-1, j, k, l)

            r = fd / bd
            psi1 = max(0., min(2*r, (2 + r)/3., 2.))
            psi1 = (1 - (1 - psi1)*ilimiter_switch )
            r = bd / fd
            psi2 = max(0., min(2*r, (2 + r)/3., 2.))
            psi2 = (1 - (1 - psi2)*ilimiter_switch )

            ! right face of last interior cell
            x_qp_left(i+1, j, k, l) = qp(i, j, k, l) + 0.25*phi* &
                (((1.-kappa) * psi1 * bd) + ((1.+kappa) * psi2 * fd))

            ! left face of last interior cell
            x_qp_right(i, j, k, l) = qp(i, j, k, l) - 0.25*phi* &
                (((1.+kappa) * psi1 * bd) + ((1.-kappa) * psi2 * fd))
         end if
         end do
        end do
       end do
      end do

    end subroutine reconstruct_imax


    subroutine reconstruct_jmin()

      implicit none
      integer :: i, j, k, l
      real :: psi1, psi2, fd, bd, r
      real :: kappa, phi

      phi = 1.0
      kappa = -1.0

      do l = 1, n_var
       do k = 1, kmx - 1
        do j = 1, 1
         do i = 1, imx - 1

          ! first ghost cell 0 right face
          y_qp_left(i, j, k, l) = 0.5 * (qp(i, j, k, l) + qp(i, j-1, k, l))

          if (ppm_flag==1) then
            fd = qp(i, j+1, k, l) - qp(i, j, k, l)
            bd = qp(i, j, k, l) - qp(i, j-1, k, l)

            r = fd / bd
            psi1 = max(0., min(2*r, (2 + r)/3., 2.))
            psi1 = (1 - (1 - psi1)*ilimiter_switch )
            r = bd / fd
            psi2 = max(0., min(2*r, (2 + r)/3., 2.))
            psi2 = (1 - (1 - psi2)*ilimiter_switch )

            ! right face of first j cell
            y_qp_left(i, j+1, k, l) = qp(i, j, k, l) + 0.25*phi* &
                (((1-kappa) * psi1 * bd) + ((1+kappa) * psi2 * fd))

            ! left face of first j cell
            y_qp_right(i, j, k, l) = qp(i, j, k, l) - 0.25*phi* &
                (((1+kappa) * psi1 * bd) + ((1-kappa) * psi2 * fd))
         end if
         end do
        end do
       end do
      end do

    end subroutine reconstruct_jmin


    subroutine reconstruct_jmax()

      implicit none
      integer :: i, j, k, l
      real :: psi1, psi2, fd, bd, r
      real :: kappa, phi

      phi = 1.0
      kappa = -1.0

      do l = 1, n_var
       do k = 1, kmx - 1
        do j = jmx-1, jmx-1
         do i = 1, imx - 1

          ! ghost cell jmx left face.
          y_qp_right(i, j+1, k, l) = 0.5 * (qp(i, j, k, l) + qp(i, j+1, k, l))

          if (ppm_flag==1) then
            fd = qp(i, j+1, k, l) - qp(i, j, k, l)
            bd = qp(i, j, k, l) - qp(i, j-1, k, l)
            r = fd / bd
            psi1 = max(0., min(2*r, (2 + r)/3., 2.))
            psi1 = (1 - (1 - psi1)*ilimiter_switch )
            r = bd / fd
            psi2 = max(0., min(2*r, (2 + r)/3., 2.))
            psi2 = (1 - (1 - psi2)*ilimiter_switch )

            ! right face of last j cell
            y_qp_left(i, j+1, k, l) = qp(i, j, k, l) + 0.25*phi* &
                (((1-kappa) * psi1 * bd) + ((1+kappa) * psi2 * fd))
          
            ! left face of last j cell
            y_qp_right(i, j, k, l) = qp(i, j, k, l) - 0.25*phi* &
                (((1+kappa) * psi1 * bd) + ((1-kappa) * psi2 * fd))
         end if
         end do
        end do
       end do
      end do

    end subroutine reconstruct_jmax


    subroutine reconstruct_kmin()

      implicit none
      real :: psi1, psi2, fd, bd, r
      integer :: i, j, k, l
      real :: kappa, phi
      
      phi = 1.0
      kappa = -1.0

      do k = 1, 1
       do l = 1, n_var
        do j = 1, jmx - 1
         do i = 1, imx - 1

          ! ghost cell 0 k right face.
          z_qp_left(i, j, k, l) = 0.5 * (qp(i, j, k, l) + qp(i, j, k-1, l))

          if (ppm_flag==1) then

            fd = qp(i, j, k+1, l) - qp(i, j, k, l)
            bd = qp(i, j, k, l) - qp(i, j, k-1, l)

            r = fd / bd
            psi1 = max(0., min(2*r, (2 + r)/3., 2.))
            psi1 = (1 - (1 - psi1)*ilimiter_switch )
            r = bd / fd
            psi2 = max(0., min(2*r, (2 + r)/3., 2.))
            psi2 = (1 - (1 - psi2)*ilimiter_switch )
            
            ! right face of first k cell
            z_qp_left(i, j, k+1, l) = qp(i, j, k, l) + 0.25*phi* &
                (((1-kappa) * psi1 * bd) + ((1+kappa) * psi2 * fd))

            ! left face of first k cell
            z_qp_right(i, j, k, l) = qp(i, j, k, l) - 0.25*phi* &
                (((1+kappa) * psi1 * bd) + ((1-kappa) * psi2 * fd))
         end if
         end do
        end do
       end do
      end do

    end subroutine reconstruct_kmin


    subroutine reconstruct_kmax()

      implicit none
      real :: psi1, psi2, fd, bd, r
      integer :: i, j, k, l
      real :: kappa, phi
    
      phi = 1.0
      kappa = -1.0

      do k = kmx-1, kmx-1
       do l = 1, n_var
        do j = 1, jmx - 1
         do i = 1, imx - 1
          ! left face of kmx ghost cell
          z_qp_right(i, j, k+1, l) = 0.5 * (qp(i, j, k, l) + qp(i, j, k+1, l))

          if (ppm_flag==1) then

            fd = qp(i, j, k+1, l) - qp(i, j, k, l)
            bd = qp(i, j, k, l) - qp(i, j, k-1, l)

            r = fd / bd
            psi1 = max(0., min(2*r, (2 + r)/3., 2.))
            psi1 = (1 - (1 - psi1)*ilimiter_switch )
            r = bd / fd
            psi2 = max(0., min(2*r, (2 + r)/3., 2.))
            psi2 = (1 - (1 - psi2)*ilimiter_switch )

            ! right face of last k interior cell
            z_qp_left(i, j, k+1, l) = qp(i, j, k, l) + 0.25*phi* &
                (((1-kappa) * psi1 * bd) + ((1+kappa) * psi2 * fd))

            ! left face of last k cell
            z_qp_right(i, j, k, l) = qp(i, j, k, l) - 0.25*phi* &
                (((1+kappa) * psi1 * bd) + ((1-kappa) * psi2 * fd))
         end if
         end do
        end do
       end do
      end do

    end subroutine reconstruct_kmax

end module boundary_state_reconstruction
