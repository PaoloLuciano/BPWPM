# Math Utils for the bpwpm package
#-------------------------------------------------------------------------------
#' Piece wise polinomial expansion for X (PWP)
#'
#' Calculates and returns a list of matrixes, each one representing a PWP
#' expansion for dimention d. Combines all of the parameters on a relatively
#' fast computation of basis expansion for X described on the thesis and on
#' (Denison, Mallik and Smith, 1998).
#'
#' @inheritParams bpwpm_gibbs
#' @inheritParams calculate_F
#' @param tau matrix containing the nodes in which to split the Piecewise
#' Polinomials
#'
#' @return A list of PWP expansion matrixes for each dimention d.
#' @export
#'
calculate_Phi <- function(X, M, J, K, d, tau, indep_terms){

    # Phi is a list containing the basis transformations matrices for each dimension j.
    # For now, this basis expansion is done following the formula on the thesis, optimized as much as posible
    Phi <- list()

    if (indep_terms) {
        for(j in seq(1,d)){

            # Creating the first basis polinomial
            Phi_partial <- sapply(X = seq(0, M-1), FUN = function(x,y){y^x}, y = X[ , j])

            # Piecewise part
            for(k in seq(1,J-1)){

                # A diagram of this can be found on the thesis
                # Note that in the limit case that K = 0 we need to make adjustments since 0^0 = 1
                if(K != 0){
                    Phi_partial <- cbind(Phi_partial, sapply(X = seq(K, M-1),
                                                             FUN = function(x,y){y^x},
                                                             y = pmax(0, X[ ,j] - tau[k,j])))
                }
                else{
                    temp <- pmax(0, X[ ,j] - tau[k,j])
                    temp[temp > 0] <- 1
                    Phi_partial <- cbind(Phi_partial, temp)

                    if(M > 1){
                        Phi_partial <- cbind(Phi_partial, sapply(X = seq(1,M-1),
                                                                 FUN = function(x,y){y^x},
                                                                 y = pmax(0, X[ ,j] - tau[k,j])))
                    }
                }
            }

            Phi[[j]] <- Phi_partial
        }
    }else{
        if(K == 0){
            stop("For correct specification of the model K must be at least 1")
            geterrmessage()
        }

        for(j in seq(1,d)){

            # Creating the first basis polinomial
            Phi_partial <- sapply(X = seq(1, M-1), FUN = function(x,y){y^x}, y = X[ , j])

            # Piecewise part
            for(k in seq(1,J-1)){

                # A diagram of this can be found on the thesis
                # Note that in the limit case that K = 0 we need to make adjustments since 0^0 = 1
                if(K != 0){
                    Phi_partial <- cbind(Phi_partial, sapply(X = seq(K, M-1),
                                                             FUN = function(x,y){y^x},
                                                             y = pmax(0, X[ ,j] - tau[k,j])))
                }
                else{
                    temp <- pmax(0, X[ ,j] - tau[k,j])
                    temp[temp > 0] <- 1
                    Phi_partial <- cbind(Phi_partial, temp)

                    if(M > 1){
                        Phi_partial <- cbind(Phi_partial, sapply(X = seq(1,M-1),
                                                                 FUN = function(x,y){y^x},
                                                                 y = pmax(0, X[ ,j] - tau[k,j])))
                    }
                }
            }

            Phi[[j]] <- Phi_partial
        }
    }


    return(Phi)

}

#-------------------------------------------------------------------------------

#' F matrix calculation
#'
#' Function for calculating the F matrix, described on the thesis.
#' This is the transformed input matrix that depends on the piecewise polinomial
#' expansion Phi and a set of weights w.
#'
#' @param Phi Piecewise Polinomail expansion for an input matrix X previosly
#'  calculated by \code{\link{calculate_Phi}}
#' @param w Set of weights for which to calculate F. Numerical matrix of size
#' (N*d)
#' @param d Number of dimentions, this parameter helps to improve efficiency
#'
#' @return F matrix
#' @export
#'
calculate_F <- function(Phi, w, d){


    # Calculating F matrix
    mat_F <- crossprod(t(Phi[[1]]),w[,1])

    if(d>1){
        for(j in seq(2,d)){
            mat_F <- cbind(mat_F,crossprod(t(Phi[[j]]),w[,j]))
        }
    }

    # Adding independent term
    mat_F <- cbind(rep(1,dim(mat_F)[1]), mat_F)
    return(mat_F)
}

#-------------------------------------------------------------------------------

#' Log Loss
#'
#' An implementation of the Log-Loss function for the binomial case
#'
#' @inheritParams bpwpm_gibbs
#' @param p Vector of fitted probabilities for each Y.
#' @param eps Machine error to hanlde limit cases on the logarithm function
#'
#' @return The value of the Log Loss function (numeric). The smaller, the better
#' @export
#'
#' @examples log_loss(true_values, fitted probabilities)
#' log_loss(true_values, fitted probabilities)
#' log_loss(true_values, fitted probabilities, 1e-30, FALSE)
log_loss <- function(Y, p, eps = 1e-15, verb = TRUE){

    if(class(Y) == "factor"){
        Y <- as.integer(Y) -1
    }

    p_corrected = pmin(pmax(p, eps), 1-eps)
    ll <- - sum (Y * log(p_corrected) + (1 - Y) * log(1 - p_corrected))/length(Y)

    if(verb){
        cat("\nLog_Loss: ",ll, sep ="")
    }

    return(- sum (Y * log(p_corrected) + (1 - Y) * log(1 - p_corrected))/length(Y))
}

#-------------------------------------------------------------------------------

#' Mode
#'
#' Calculates the mode of a vector. Ties are resolved by the first element
#'
#' @param x A numeric vector
#'
#' @return The mode of the vector
#'
mode <- function(x) {

    ux <- unique(x)
    ux[which.max(tabulate(match(x, ux)))]
}

#-------------------------------------------------------------------------------

#' Calculate Projection Vector
#'
#' @param F_mat The PWP transformed input space, calculated by a set of \code{w}
#'  and a \code{Phi} matrix by the function \code{\link{calculate_F}}
#' @param betas The posterior puntual estimation for beta parameters calculated
#' by \code{\link{posterior_params}}
#'
#' @return A numeric vector representing the projection of \code{R^d} into
#' \code{R} given all of the parametres
#' @export
#'
calculate_projection <- function(F_mat, betas){
    return(crossprod(t(F_mat),betas))
}

#-------------------------------------------------------------------------------

#' Calculates trained model for new Data
#'
#' Given a set of parameters inherited by the \code{\link{bpwpm_gibbs}} training
#' procedure, we calculate the value of the projection function for new data.
#' This function is both used on the predict and plot_3D functions.
#' @param new_X A new set of data for which to calculate the f(x) projection
#' function
#' @param bpwpm_params A list of bpwpm parameters created by the function
#' \code{\link{posterior_params}}
#'
#' @return A vector of the projection vector for a given set of points
#' @export
#'
#' @examples (test_data, mean_params)
model_projection <- function(new_X, bpwpm_params){

    if(class(bpwpm_params) != "bpwpm_params"){
        error("Invalid class, object should be of class bpwpm_params")
        geterrmessage()
    }

    Phi <- calculate_Phi(X = new_X,
                         M = bpwpm_params$M, J = bpwpm_params$J,
                         K = bpwpm_params$K, d = bpwpm_params$d,
                         tau = bpwpm_params$tau,
                         indep_terms = bpwpm_params$indep_terms)

    F_mat <- calculate_F(Phi = Phi, bpwpm_params$w, d = bpwpm_params$d)

    return(calculate_projection(F_mat = F_mat, betas = bpwpm_params$betas))
}

#-------------------------------------------------------------------------------

#' Calculate Probabilities of Binary Outcome
#'
#' Given a model, we can calculate the corresponding fitted probabilites of the
#' random response variable Y. Whereas this is new data or the one used to train
#' the model. Since the model is a probit GLM at this point, we only need to
#' calculate the projection and then plug them on the inverse of the normal
#' gaussian acomulation function
#'
#' @inheritParams model_projection
#'
#' @return A vector of fitted probabilities for the response variable Y
#' @export
#'
posterior_probs <- function(new_X, bpwpm_params){
    if(class(bpwpm_params) != "bpwpm_params"){
        error("Invalid bpwpm parameters")
        geterrmessage()
    }

    z <- model_projection(new_X,
                          bpwpm_params)

    return(pnorm(z))
}

#-------------------------------------------------------------------------------

#' Calculate the Accuracy of the model
#'
#' Given a set of true values and their corresponding fitted probabilities,
#' the function calculates the accuracy of the model defined by:
#'  \eqn{1- #wrong prediction/# of observations}
#'
#' @inheritParams  log_loss
#'
#' @return The accuracy of the model, given the fitted probabilities and new data
#' @export
#'
#' @examples (new_Y, fitted_probs_for_data)
accuracy <- function(new_Y, p, verb = FALSE){

    if(class(new_Y) == "factor"){
        new_Y <- as.integer(Y) - 1
    }

    n <- length(new_Y)

    est_Y <- rep(0, times = n)
    est_Y[p > 0.5] <- 1

    wrongs <- sum(abs(new_Y - est_Y))

    if(verb) cat(wrongs, " incorrect categorizations\n", sep = "")

    return(1 - wrongs/n)
}

#-------------------------------------------------------------------------------
#' Contingency Table for the prediciton of a bpwpm
#'
#' @param new_Y Response variable to test the model for
#' @param p Vector of fitted probabilities
#'
#' @return The contingency table
#' @export
#'
#' @examples contingency_table(train_y, est_p)
contingency_table <- function(new_Y, p){

    if(class(new_Y) == "factor"){
        new_Y <- as.integer(Y) - 1
    }

    n <- length(new_Y)
    est_Y <- rep(0, times = n)
    est_Y[p > 0.5] <- 1

    a <- sum((new_Y + est_Y) == 0)
    b <- sum((est_Y - new_Y == 1))
    c <- sum((new_Y - est_Y == 1))
    d <- sum((new_Y + est_Y) == 2)

    ct <- base::data.frame(rbind(
                     cbind(a, b, sum(-(new_Y - 1))),
                     cbind(c, d, sum(new_Y)),
                     cbind(sum(-(est_Y - 1)), sum(est_Y), n)))

    colnames(ct) <- c("Est. Y = 0", "Est Y = 1", "Real Y - Totals")
    row.names(ct) <- c("Real Y = 0", "Real Y = 1", "Est. Y - Totals")

    return(ct)
}

#-------------------------------------------------------------------------------
#' Ergodic Mean
#'
#' Calculates the Ergodic Mean for an MCMC_Chain Matrix producede as output from
#' \code{\link{bpwpm_chain}}. It is used by the \code{\link{plot_ergodic_mean}}
#'  function, but left available for the user.
#' @param mcmc_chain
#'
#' @return The Ergodic Mean Matrix
#' @export
#'
#' @examples MA_betas <- (betas)
ergodic_mean <- function(mcmc_chain){
    return(apply(mcmc_chain,2,cumsum)/seq(1:dim(mcmc_chain)[1]))
}
