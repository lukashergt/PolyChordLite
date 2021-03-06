module priors_module
    use utils_module, only: dp
    implicit none

    integer, parameter :: unknown_type                        = 0
    integer, parameter :: uniform_type                        = 1
    integer, parameter :: log_uniform_type                    = 2
    integer, parameter :: power_uniform_type                  = 3
    integer, parameter :: gaussian_type                       = 4
    integer, parameter :: half_gaussian_type                  = 5
    integer, parameter :: exponential_type                    = 6
    integer, parameter :: sorted_uniform_type                 = 7
    integer, parameter :: sorted_gaussian_type                = 8
    integer, parameter :: sorted_half_gaussian_type           = 9
    integer, parameter :: sorted_exponential_type             = 10
    integer, parameter :: adaptive_sorted_uniform_type        = 11
    integer, parameter :: adaptive_sorted_gaussian_type       = 12
    integer, parameter :: adaptive_sorted_half_gaussian_type  = 13
    integer, parameter :: adaptive_sorted_exponential_type    = 14
    integer, parameter :: nn_adaptive_layer_gaussian_type     = 15

    type prior
        integer :: npars = 0
        integer :: prior_type = unknown_type
        integer, dimension(:), allocatable :: hypercube_indices
        integer, dimension(:), allocatable :: physical_indices
        real(dp), dimension(:), allocatable :: parameters

    end type prior


    contains


    !============= Separable Priors ================================================


    !============= Uniform (Separable) ================================================

    function uniform_htp(hypercube_coords,parameters) result(physical_coords)

        implicit none
        !> The hypercube coordinates to be transformed
        real(dp), intent(in), dimension(:) :: hypercube_coords
        !> The parameters of the transformation
        real(dp), intent(in), dimension(:) :: parameters
        !> The transformed coordinates
        real(dp), dimension(size(hypercube_coords)) :: physical_coords
        ! This is a fairly simple transformation, each parameter is transformed as
        ! hypercube_coord -> min + hypercube_coord * (max-min)
        ! odd indices of the parameters array are the minimums
        ! even indices of the parameters array are the maximums
        physical_coords = parameters(1::2) + (parameters(2::2) - parameters(1::2) ) * hypercube_coords

    end function uniform_htp

    function uniform_pth(physical_coords,parameters) result(hypercube_coords)

        implicit none
        !> The physical coordinates to be transformed
        real(dp), intent(in), dimension(:) :: physical_coords
        !> The parameters of the transformation
        real(dp), intent(in), dimension(:) :: parameters
        !> The transformed coordinates
        real(dp), dimension(size(physical_coords)) :: hypercube_coords
        hypercube_coords = (physical_coords - parameters(1::2)) / (parameters(2::2) - parameters(1::2) )

    end function uniform_pth


    !============= Gaussian (Separable) ===============================================

    function gaussian_htp(hypercube_coords,parameters) result(physical_coords)

        use utils_module, only: inv_normal_cdf
        implicit none
        !> The hypercube coordinates to be transformed
        real(dp), intent(in), dimension(:) :: hypercube_coords
        !> The parameters of the transformation
        real(dp), intent(in), dimension(:) :: parameters
        !> The transformed coordinates
        real(dp), dimension(size(hypercube_coords)) :: physical_coords
        ! Transform via the inverse normal cumulative distribution function
        physical_coords = inv_normal_cdf(hypercube_coords)
        ! Scale by the standard deviation and shift by the mean
        physical_coords = parameters(1::2) + parameters(2::2) * physical_coords

    end function gaussian_htp

    function gaussian_pth(physical_coords,parameters) result(hypercube_coords)

        use utils_module, only: normal_cdf
        implicit none
        !> The physical coordinates to be transformed
        real(dp), intent(in), dimension(:) :: physical_coords
        !> The parameters of the transformation
        real(dp), intent(in), dimension(:) :: parameters
        !> The transformed coordinates
        real(dp), dimension(size(physical_coords)) :: hypercube_coords
        integer :: npars 
        npars=size(physical_coords)
        ! Scale by the standard deviation and shift by the mean
        ! odd indices of the parameters array are the means
        ! even indices of the parameters array are the stdevs
        hypercube_coords = ( physical_coords - parameters(1::2) )/parameters(2::2)
        ! Transform via the normal cumulative distribution function
        hypercube_coords = normal_cdf(hypercube_coords)

    end function gaussian_pth


    !============= Log-Uniform (Separable) ============================================

    function log_uniform_htp(hypercube_coords,parameters) result(physical_coords)

        implicit none
        !> The hypercube coordinates to be transformed
        real(dp), intent(in), dimension(:) :: hypercube_coords
        !> The parameters of the transformation
        real(dp), intent(in), dimension(:) :: parameters
        !> The transformed coordinates
        real(dp), dimension(size(hypercube_coords)) :: physical_coords
        ! hypercube_coord -> min * (max/min)**hypercube_coord
        ! Lower half of the parameters array are the minimums
        ! Upper half of the parameters array are the maximums
        physical_coords = parameters(1::2) * (parameters(2::2)/parameters(1::2)) ** hypercube_coords

    end function log_uniform_htp

    function log_uniform_pth(physical_coords,parameters) result(hypercube_coords)

        implicit none
        !> The physical coordinates to be transformed
        real(dp), intent(in), dimension(:) :: physical_coords
        !> The parameters of the transformation
        real(dp), intent(in), dimension(:) :: parameters
        !> The transformed coordinates
        real(dp), dimension(size(physical_coords)) :: hypercube_coords
        ! hypercube_coord -> min * (max/min)**hypercube_coord
        ! Lower half of the parameters array are the minimums
        ! Upper half of the parameters array are the maximums
        hypercube_coords = log(physical_coords/parameters(1::2)) / log(parameters(2::2)/parameters(1::2))

    end function log_uniform_pth


    !============= Power uniform (Separable) ===============================================

    ! Prior such that theta^power is uniformly distributed.
    ! Power must be negative.
    function power_uniform_htp(hypercube_coords,parameters) result(physical_coords)

        use utils_module, only: inv_normal_cdf
        implicit none
        !> The hypercube coordinates to be transformed
        real(dp), intent(in), dimension(:) :: hypercube_coords
        !> The parameters of the transformation
        real(dp), intent(in), dimension(:) :: parameters
        !> The transformed coordinates
        real(dp), dimension(size(hypercube_coords)) :: physical_coords
        !> The Constants
        real(dp), dimension(size(hypercube_coords)) :: const
        const = 1.0 / abs((parameters(1::3) ** (1.0 / parameters(3::3))) -  (parameters(2::3) ** (1.0 / parameters(3::3))))
        physical_coords = (parameters(1::3) ** (1.0 / parameters(3::3))) - (hypercube_coords / const)
        physical_coords = physical_coords ** parameters(3::3)

    end function power_uniform_htp


    !============= Half Gaussian (Separable) ===============================================

    function half_gaussian_htp(hypercube_coords,parameters) result(physical_coords)

        use utils_module, only: inv_normal_cdf
        implicit none
        !> The hypercube coordinates to be transformed
        real(dp), intent(in), dimension(:) :: hypercube_coords
        !> The parameters of the transformation
        real(dp), intent(in), dimension(:) :: parameters
        !> The transformed coordinates
        real(dp), dimension(size(hypercube_coords)) :: physical_coords
        ! Transform to upper half of hypercube
        physical_coords = 0.5 + (0.5 * hypercube_coords)
        ! Apply gaussian_htp
        physical_coords = gaussian_htp(physical_coords, parameters)

    end function half_gaussian_htp


    !============= Exponential (Separable) ===============================================

    function exponential_htp(hypercube_coords,parameters) result(physical_coords)

        use utils_module, only: inv_normal_cdf
        implicit none
        !> The hypercube coordinates to be transformed
        real(dp), intent(in), dimension(:) :: hypercube_coords
        !> The parameters of the transformation
        real(dp), intent(in), dimension(:) :: parameters
        !> The transformed coordinates
        real(dp), dimension(size(hypercube_coords)) :: physical_coords
        physical_coords = -log(1 - hypercube_coords) / parameters(1::1)

    end function exponential_htp


    !============= Sorted Priors ================================================

    !> This transforms the unit hypercube to a "forced identifiablity" prior.
    !! This means that the \f$(\theta_1,\theta_2,\ldots,\theta_n)\f$ variables are uniformly distributed in the
    !! physical prior space between \f$\theta_\mathrm{min}\f$ and \f$\theta_\mathrm{max}\f$, but have been sorted so
    !! that \f$(\theta_1<\theta_2<\ldots<\theta_n)\f$. This amounts to choosing a non-separable prior such that:
    !!
    !! \f[ \pi_n(\theta_n)            
    !!     =  n  \frac{(\theta_n-\theta_\mathrm{min})^{n-1}}{(\theta_\mathrm{max}-\theta_\mathrm{min})^n}
    !!     \qquad  \theta_\mathrm{min}<\theta_n<\theta_\mathrm{max} \f]
    !! \f[ \pi_{n-1}(\theta_{n-1}|\theta_n)            
    !!     =(n-1)\frac{(\theta_{n-1}-\theta_\mathrm{min})^{n-2}}{(\theta_\mathrm{max}-\theta_\mathrm{min})^{n-1}}
    !!     \qquad  \theta_\mathrm{min}<\theta_{n-1}<\theta_n \f]
    !! \f[ \pi_{n-2}(\theta_{n-2}|\theta_n,\theta{n-1})            
    !!     =(n-2)\frac{(\theta_{n-2}-\theta_\mathrm{min})^{n-3}}{(\theta_\mathrm{max}-\theta_\mathrm{min})^{n-2}}
    !!     \qquad  \theta_\mathrm{min}<\theta_{n-2}<\theta_{n-1} \f]
    !! \f[...\f]
    !! \f[ \pi_1(\theta_1|\theta_n,\ldots,\theta_2)            
    !!     =\frac{1}{(\theta_\mathrm{max}-\theta_\mathrm{min})}
    !!     \qquad  \theta_\mathrm{min}<\theta_1<\theta_2 \f]
    !!
    !! The first of these is the probability density for the largest of n points
    !! in \f$[\theta_\mathrm{min},\theta_\mathrm{max}]\f$.
    !!
    !! For the next highest point it is the smallest of \f$n-1\f$ points in the
    !! range \f$[\theta_\mathrm{min},\theta_n]\f$. 
    !!
    !! To perform this transformation, it is cleanest to do this in two
    !! steps. First perform the above transformations using the inverse of the cumulative
    !! distribution function:
    !! \f[ CDF^{-1}(x) = x^{1/n} \f]
    !!
    !! Then transform the unit hypercube into the physical space with a linear
    !! rescaling

    function sort_hypercube(hypercube_coords) result(sorted_coords)

        implicit none
        !> The hypercube coordinates to be transformed
        real(dp), intent(in), dimension(:) :: hypercube_coords
        !> The transformed coordinates
        real(dp), dimension(size(hypercube_coords)) :: sorted_coords
        integer n_prior ! the dimension
        ! Get the size of the array
        n_prior = size(hypercube_coords)
        ! Transform the largest index to the largest of n_prior variables in [0,1]
        sorted_coords(n_prior) = hypercube_coords(n_prior)**(1d0/n_prior)
        ! Then for the remaining variables, transform them to the largest of the
        ! remaining variables, and rescale so that the variable one larger is
        ! the maximum
        do n_prior=n_prior-1,1,-1
            sorted_coords(n_prior) = hypercube_coords(n_prior)**(1d0/n_prior)*sorted_coords(n_prior+1)
        end do

    end function sort_hypercube


    !============= Sorted Uniform =====================================================

    function sorted_uniform_htp(hypercube_coords,parameters) result(physical_coords)

        implicit none
        !> The hypercube coordinates to be transformed
        real(dp), intent(in), dimension(:) :: hypercube_coords
        !> The parameters of the transformation
        real(dp), intent(in), dimension(:) :: parameters
        !> The transformed coordinates
        real(dp), dimension(size(hypercube_coords)) :: physical_coords
        ! Sort the coordinates
        physical_coords = sort_hypercube(hypercube_coords)
        ! Apply the prior
        physical_coords = uniform_htp(physical_coords, parameters)

    end function sorted_uniform_htp

    function sorted_uniform_pth(physical_coords,parameters) result(hypercube_coords)

        implicit none
        !> The physical coordinates to be transformed
        real(dp), intent(in), dimension(:) :: physical_coords
        !> The parameters of the transformation
        real(dp), intent(in), dimension(:) :: parameters
        !> The transformed coordinates
        real(dp), dimension(size(physical_coords)) :: hypercube_coords
        integer n_prior ! the dimension
        integer i_prior ! the dimension
        ! Get the size of the array
        n_prior = size(physical_coords)
        ! Rescale back to [0,1]
        hypercube_coords =  (physical_coords - parameters(1)) / (parameters(2)-parameters(1))  
        ! Undo the trasformation piece by piece
        do i_prior = 1,n_prior-1
            hypercube_coords(i_prior) = ( hypercube_coords(i_prior)/hypercube_coords(i_prior+1) )**i_prior
        end do
        hypercube_coords(n_prior) = hypercube_coords(n_prior)**n_prior

    end function sorted_uniform_pth


    !============= Sorted Gaussian =====================================================

    function sorted_gaussian_htp(hypercube_coords,parameters) result(physical_coords)

        implicit none
        !> The hypercube coordinates to be transformed
        real(dp), intent(in), dimension(:) :: hypercube_coords
        !> The parameters of the transformation
        real(dp), intent(in), dimension(:) :: parameters
        !> The transformed coordinates
        real(dp), dimension(size(hypercube_coords)) :: physical_coords
        ! Sort the coordinates
        physical_coords = sort_hypercube(hypercube_coords)
        ! Apply the prior
        physical_coords = gaussian_htp(physical_coords, parameters)

    end function sorted_gaussian_htp


    !============= Sorted Half Gaussian =====================================================

    function sorted_half_gaussian_htp(hypercube_coords,parameters) result(physical_coords)

        implicit none
        !> The hypercube coordinates to be transformed
        real(dp), intent(in), dimension(:) :: hypercube_coords
        !> The parameters of the transformation
        real(dp), intent(in), dimension(:) :: parameters
        !> The transformed coordinates
        real(dp), dimension(size(hypercube_coords)) :: physical_coords
        ! Sort the coordinates
        physical_coords = sort_hypercube(hypercube_coords)
        ! Apply the prior
        physical_coords = half_gaussian_htp(physical_coords, parameters)

    end function sorted_half_gaussian_htp


    !============= Sorted Exponential =====================================================

    function sorted_exponential_htp(hypercube_coords,parameters) result(physical_coords)

        implicit none
        !> The hypercube coordinates to be transformed
        real(dp), intent(in), dimension(:) :: hypercube_coords
        !> The parameters of the transformation
        real(dp), intent(in), dimension(:) :: parameters
        !> The transformed coordinates
        real(dp), dimension(size(hypercube_coords)) :: physical_coords
        ! Sort the coordinates
        physical_coords = sort_hypercube(hypercube_coords)
        ! Apply the prior
        physical_coords = exponential_htp(physical_coords, parameters)

    end function sorted_exponential_htp


    !============= Adaptive Sorted Priors ===============================================

    ! Uniform prior on first parameter in (0.5, nparams - 0.5) rounded to int to give number of basis functions to use
    ! Then sort only the basis functions to be used
    function adaptive_sorted_transform(hypercube_coords) result(transformed_coords)

        implicit none
        !> The hypercube coordinates to be transformed
        real(dp), intent(in), dimension(:) :: hypercube_coords
        !> The transformed coordinates
        real(dp), dimension(size(hypercube_coords)) :: transformed_coords
        !> Number of functions selected by adaptive parameter
        integer nfunc
        transformed_coords = hypercube_coords
        ! Scale the first parameter, which when rounded to nearest int determines the number of functions to use
        transformed_coords(1) = (0.5 + (hypercube_coords(1) * (size(hypercube_coords) - 1)))
        ! Get nfunc = first coord rounded to nearest int. Note INT rounds down so need to add 0.5
        nfunc = INT(transformed_coords(1) + 0.5)
        ! Sort the next nfunc coords
        transformed_coords(2:nfunc + 1) = sort_hypercube(transformed_coords(2:nfunc + 1))

    end function adaptive_sorted_transform


    !============= Adaptive Sorted Uniform =====================================================

    function adaptive_sorted_uniform_htp(hypercube_coords,parameters) result(physical_coords)

        implicit none
        !> The hypercube coordinates to be transformed
        real(dp), intent(in), dimension(:) :: hypercube_coords
        !> The parameters of the transformation
        real(dp), intent(in), dimension(:) :: parameters
        !> The transformed coordinates
        real(dp), dimension(size(hypercube_coords)) :: physical_coords
        ! Sort the coordinates and scale first coord
        physical_coords = adaptive_sorted_transform(hypercube_coords)
        ! Apply the prior
        physical_coords(2:) = uniform_htp(physical_coords(2:), parameters(3:))

    end function adaptive_sorted_uniform_htp


    !============= Adaptive Sorted Gaussian =====================================================

    function adaptive_sorted_gaussian_htp(hypercube_coords,parameters) result(physical_coords)

        implicit none
        !> The hypercube coordinates to be transformed
        real(dp), intent(in), dimension(:) :: hypercube_coords
        !> The parameters of the transformation
        real(dp), intent(in), dimension(:) :: parameters
        !> The transformed coordinates
        real(dp), dimension(size(hypercube_coords)) :: physical_coords
        ! Sort the coordinates
        physical_coords = adaptive_sorted_transform(hypercube_coords)
        ! Apply the prior
        physical_coords(2:) = gaussian_htp(physical_coords(2:), parameters(3:))

    end function adaptive_sorted_gaussian_htp


    !============= Adaptive Sorted Half Gaussian ================================================

    function adaptive_sorted_half_gaussian_htp(hypercube_coords,parameters) result(physical_coords)

        implicit none
        !> The hypercube coordinates to be transformed
        real(dp), intent(in), dimension(:) :: hypercube_coords
        !> The parameters of the transformation
        real(dp), intent(in), dimension(:) :: parameters
        !> The transformed coordinates
        real(dp), dimension(size(hypercube_coords)) :: physical_coords
        ! Sort the coordinates
        physical_coords = adaptive_sorted_transform(hypercube_coords)
        ! Apply the prior
        physical_coords(2:) = half_gaussian_htp(physical_coords(2:), parameters(3:))

    end function adaptive_sorted_half_gaussian_htp


    !============= Adaptive Sorted Exponential ==================================================

    function adaptive_sorted_exponential_htp(hypercube_coords,parameters) result(physical_coords)

        implicit none
        !> The hypercube coordinates to be transformed
        real(dp), intent(in), dimension(:) :: hypercube_coords
        !> The parameters of the transformation
        real(dp), intent(in), dimension(:) :: parameters
        !> The transformed coordinates
        real(dp), dimension(size(hypercube_coords)) :: physical_coords
        ! Sort the coordinates
        physical_coords = adaptive_sorted_transform(hypercube_coords)
        ! Apply the prior
        physical_coords(2:) = exponential_htp(physical_coords(2:), parameters(2:))

    end function adaptive_sorted_exponential_htp


    !============= NN Adaptive Layer Gaussian ===================================================

    ! Used for neural networks with a number of hidden layers determined by the first parameter
    ! If there is 1 hidden layer we use the adaptive_sorted_half_gaussian. Otherwise use the adaptive sorted gaussian.
    ! See "Bayesian sparse reconstruction: a brute-force approach to astronomical imaging and machine learning" (Higson et al 2018) for more information

    function nn_adaptive_layer_gaussian_htp(hypercube_coords,parameters) result(physical_coords)

        implicit none
        !> The hypercube coordinates to be transformed
        real(dp), intent(in), dimension(:) :: hypercube_coords
        !> The parameters of the transformation
        real(dp), intent(in), dimension(:) :: parameters
        !> The transformed coordinates
        real(dp), dimension(size(hypercube_coords)) :: physical_coords
        !> Get the number of layers (currently 1 or 2)
        physical_coords = hypercube_coords
        physical_coords(1) = (0.5 + (hypercube_coords(1) * 2))
        !> Select prior based on number of layers
        IF (physical_coords(1) .LT. 1.5) THEN
            physical_coords(2:) = adaptive_sorted_half_gaussian_htp(physical_coords(2:), parameters(3:))
        ELSE
            physical_coords(2:) = adaptive_sorted_gaussian_htp(physical_coords(2:), parameters(3:))
        END IF

    end function nn_adaptive_layer_gaussian_htp


    ! =============================== Wrapper functions =====================================

    ! prior transformations
    function hypercube_to_physical(hypercube_coords,priors) result(physical_coords)

        implicit none
        type(prior), dimension(:), intent(in) :: priors
        real(dp), intent(in), dimension(:) :: hypercube_coords

        real(dp), dimension(size(hypercube_coords)) :: physical_coords

        integer :: i

        physical_coords=0d0

        do i=1,size(priors)
            select case(priors(i)%prior_type)
            case(uniform_type)
                physical_coords(priors(i)%physical_indices)= uniform_htp&
                    (hypercube_coords(priors(i)%hypercube_indices),priors(i)%parameters)
            case(log_uniform_type)
                physical_coords(priors(i)%physical_indices)= log_uniform_htp&
                    (hypercube_coords(priors(i)%hypercube_indices),priors(i)%parameters)
            case(power_uniform_type)
                physical_coords(priors(i)%physical_indices)= power_uniform_htp&
                    (hypercube_coords(priors(i)%hypercube_indices),priors(i)%parameters)
            case(gaussian_type)
                physical_coords(priors(i)%physical_indices)= gaussian_htp&
                    (hypercube_coords(priors(i)%hypercube_indices),priors(i)%parameters)
            case(half_gaussian_type)
                physical_coords(priors(i)%physical_indices)= half_gaussian_htp&
                    (hypercube_coords(priors(i)%hypercube_indices),priors(i)%parameters)
            case(exponential_type)
                physical_coords(priors(i)%physical_indices)= exponential_htp&
                    (hypercube_coords(priors(i)%hypercube_indices),priors(i)%parameters)
            case(sorted_uniform_type)
                physical_coords(priors(i)%physical_indices)= sorted_uniform_htp&
                    (hypercube_coords(priors(i)%hypercube_indices),priors(i)%parameters)
            case(sorted_gaussian_type)
                physical_coords(priors(i)%physical_indices)= sorted_gaussian_htp&
                    (hypercube_coords(priors(i)%hypercube_indices),priors(i)%parameters)
            case(sorted_half_gaussian_type)
                physical_coords(priors(i)%physical_indices)= sorted_half_gaussian_htp&
                    (hypercube_coords(priors(i)%hypercube_indices),priors(i)%parameters)
            case(sorted_exponential_type)
                physical_coords(priors(i)%physical_indices)= sorted_exponential_htp&
                    (hypercube_coords(priors(i)%hypercube_indices),priors(i)%parameters)
            case(adaptive_sorted_uniform_type)
                physical_coords(priors(i)%physical_indices)= adaptive_sorted_uniform_htp&
                    (hypercube_coords(priors(i)%hypercube_indices),priors(i)%parameters)
            case(adaptive_sorted_gaussian_type)
                physical_coords(priors(i)%physical_indices)= adaptive_sorted_gaussian_htp&
                    (hypercube_coords(priors(i)%hypercube_indices),priors(i)%parameters)
            case(adaptive_sorted_half_gaussian_type)
                physical_coords(priors(i)%physical_indices)= adaptive_sorted_half_gaussian_htp&
                    (hypercube_coords(priors(i)%hypercube_indices),priors(i)%parameters)
            case(adaptive_sorted_exponential_type)
                physical_coords(priors(i)%physical_indices)= adaptive_sorted_exponential_htp&
                    (hypercube_coords(priors(i)%hypercube_indices),priors(i)%parameters)
            case(nn_adaptive_layer_gaussian_type)
                physical_coords(priors(i)%physical_indices)= nn_adaptive_layer_gaussian_htp&
                    (hypercube_coords(priors(i)%hypercube_indices),priors(i)%parameters)
            end select
        end do

    end function hypercube_to_physical

    function physical_to_hypercube(physical_coords,priors) result(hypercube_coords)

        implicit none
        type(prior), dimension(:), intent(in) :: priors
        real(dp), intent(in), dimension(:) :: physical_coords

        real(dp), dimension(size(physical_coords)) :: hypercube_coords

        integer :: i

        hypercube_coords=0d0

        do i=1,size(priors)
            select case(priors(i)%prior_type)
            case(uniform_type)
                hypercube_coords(priors(i)%hypercube_indices)= uniform_pth&
                    (physical_coords(priors(i)%physical_indices),priors(i)%parameters)
            case(gaussian_type)
                hypercube_coords(priors(i)%hypercube_indices)= gaussian_pth&
                    (physical_coords(priors(i)%physical_indices),priors(i)%parameters)
            case(log_uniform_type)
                hypercube_coords(priors(i)%hypercube_indices)= log_uniform_pth&
                    (physical_coords(priors(i)%physical_indices),priors(i)%parameters)
            case(sorted_uniform_type)
                hypercube_coords(priors(i)%hypercube_indices)= sorted_uniform_pth&
                    (physical_coords(priors(i)%physical_indices),priors(i)%parameters)
            end select
        end do

    end function physical_to_hypercube



    function prior_log_volume(priors) result(log_volume)
        use utils_module, only: logTwoPi
        implicit none
        type(prior), dimension(:), intent(in) :: priors

        real(dp) :: log_volume
        integer :: i

        log_volume = 0

        do i=1,size(priors)
            select case(priors(i)%prior_type)
            case(uniform_type)
                log_volume = log_volume + sum( log(priors(i)%parameters(2::2)- priors(i)%parameters(1::2) )) 
            case(gaussian_type)
                log_volume = log_volume + sum( 0.5d0*logTwoPi + log(priors(i)%parameters(2::2)) )
            case(log_uniform_type)
                log_volume = log_volume + sum( log(log( priors(i)%parameters(2::2)/priors(i)%parameters(1::2) )) ) 
            case(sorted_uniform_type)
                log_volume = log_volume + log(priors(i)%parameters(2)- priors(i)%parameters(1) ) - log(gamma(1d0+priors(i)%npars)) 
            end select
        end do

    end function prior_log_volume




    !> This function converts from strings to integer prior types
    function prior_type_from_string(string) result(prior_type)
        use utils_module, only: STR_LENGTH
        implicit none
        character(len=*),intent(in) :: string
        integer :: prior_type

        character(len=STR_LENGTH) :: string_buf

        write(string_buf,'(A)') string

        select case(trim(string_buf))

        case('uniform')
            prior_type=uniform_type
        case('log_uniform')
            prior_type=log_uniform_type
        case('power_uniform')
            prior_type=power_uniform_type
        case('gaussian')
            prior_type=gaussian_type
        case('half_gaussian')
            prior_type=half_gaussian_type
        case('exponential')
            prior_type=exponential_type
        case('sorted_uniform')
            prior_type=sorted_uniform_type
        case('sorted_gaussian')
            prior_type=sorted_gaussian_type
        case('sorted_half_gaussian')
            prior_type=sorted_half_gaussian_type
        case('sorted_exponential')
            prior_type=sorted_exponential_type
        case('adaptive_sorted_uniform')
            prior_type=adaptive_sorted_uniform_type
        case('adaptive_sorted_gaussian')
            prior_type=adaptive_sorted_gaussian_type
        case('adaptive_sorted_half_gaussian')
            prior_type=adaptive_sorted_half_gaussian_type
        case('adaptive_sorted_exponential')
            prior_type=adaptive_sorted_exponential_type
        case('nn_adaptive_layer_gaussian')
            prior_type=nn_adaptive_layer_gaussian_type
        case default
            prior_type=unknown_type
        end select

    end function prior_type_from_string



    !> This function converts an array of parameters into a set of prior blocks
    subroutine create_priors(priors,params,settings)
        use settings_module,   only: program_settings
        use params_module, only: param_type
        use utils_module,  only: relabel
        implicit none 
        type(prior), dimension(:), allocatable,intent(out)   :: priors  !> The array of priors to be returned
        type(param_type),dimension(:),allocatable,intent(in) :: params  !> Parameter array
        type(program_settings), intent(inout) :: settings !> Program settings

        integer, dimension(size(params)) :: prior_blocks
        integer :: num_blocks

        integer :: num_params
        integer :: i_params

        integer, dimension(size(params)) :: speeds_old
        integer, dimension(size(params)) :: speeds
        integer :: i_speed
        integer, parameter :: max_speed = huge(1)

        integer, dimension(size(params)) :: hypercube_indices
        integer :: i_hypercube

        num_params = size(params) 

        ! First determine how many prior blocks there are
        do i_params=1,num_params
            prior_blocks(i_params) = params(i_params)%prior_block
        end do
        ! re-organise these labels
        prior_blocks = relabel(prior_blocks,num_blocks)

        ! Allocate the priors array
        if(allocated(priors)) deallocate(priors)
        allocate(priors(num_blocks))


        ! Next determine the hypercube indices via the grades

        ! Find the various speeds:
        do i_params=1,num_params
            speeds_old(i_params) = params(i_params)%speed
        end do

        ! Relabel them with the numbers 1,2,3...
        i_speed = 0
        do while(any(speeds_old/=max_speed))
            i_speed=i_speed+1
            where(speeds_old==minval(speeds_old))
                speeds=i_speed
                speeds_old=max_speed
            end where
        end do

        if(allocated(settings%grade_dims)) deallocate(settings%grade_dims)
        allocate(settings%grade_dims(maxval(speeds)))

        ! Now assign hypercube indices
        i_hypercube = 0
        do i_speed=1,maxval(speeds)
            do i_params=1,num_params
                if(speeds(i_params)==i_speed) then
                    i_hypercube=i_hypercube+1
                    hypercube_indices(i_params) = i_hypercube
                end if
            end do
            settings%grade_dims(i_speed) = count(speeds==i_speed)
        end do

        allocate(settings%sub_clustering_dimensions(count([ (params(i_params)%sub_cluster, i_params=1,num_params) ])))
        settings%sub_clustering_dimensions = pack(hypercube_indices, [ (params(i_params)%sub_cluster, i_params=1,num_params) ] ) 


        ! Finally, add each of the parameters to the prior blocks, coupled with the hypercube information
        do i_params=1,num_params
            call add_param_to_prior(priors(prior_blocks(i_params)),params(i_params),i_params,hypercube_indices(i_params))
        end do

    end subroutine create_priors

    subroutine add_param_to_prior(priori,param,physical_index,hypercube_index)
        use params_module, only: param_type
        use array_module,  only: reallocate
        use abort_module,  only: halt_program
        implicit none
        type(prior), intent(inout)   :: priori          !> The prior to be added to
        type(param_type),intent(in)  :: param           !> The params to add
        integer, intent(in)          :: physical_index  !> The position in the likelihood call
        integer, intent(in)          :: hypercube_index !> The position in the unit hypercube

        ! Allocate physical indices if it is unallocated
        if(.not.allocated(priori%physical_indices))  allocate(priori%physical_indices(0))
        if(.not.allocated(priori%hypercube_indices)) allocate(priori%hypercube_indices(0))

        priori%npars=priori%npars+1                               ! Increment the number of parameters

        call reallocate(priori%physical_indices,priori%npars) ! reallocate the physical index array
        priori%physical_indices(priori%npars) = physical_index    ! give it the physical index of this point

        call reallocate(priori%hypercube_indices,priori%npars) ! reallocate the physical index array
        priori%hypercube_indices(priori%npars) = hypercube_index   ! give it the physical index of this point

        if(priori%prior_type==unknown_type) then
            priori%prior_type = param%prior_type
        else if(priori%prior_type/= param%prior_type) then
            call halt_program('create_priors error: parameter '//trim(param%paramname)// ' must have the same prior type as others within its block')
        end if

        ! Allocate the prior parameters if its unallocated
        if (.not. allocated(priori%parameters) ) allocate(priori%parameters(0))
        ! expand the parameters array by size prior_params
        call reallocate(priori%parameters,size(priori%parameters)+size(param%prior_params))
        ! add these to the end
        priori%parameters(size(priori%parameters)-size(param%prior_params)+1:size(priori%parameters)) =param%prior_params


    end subroutine add_param_to_prior






end module priors_module
