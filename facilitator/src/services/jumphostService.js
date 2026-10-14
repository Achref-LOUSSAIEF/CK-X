/**
 * Jumphost Service
 * 
 * This service handles SSH connections to the jumphost for exam environment
 * preparation and cleanup operations. It provides two main functionalities:
 * 1. Setting up the exam environment (prepare-exam-env)
 * 2. Cleaning up the exam environment after the exam is completed
 * 3. Evaluating exam by running verification scripts
 */

const sshService = require('./sshService');
const redisClient = require('../utils/redisClient');
const logger = require('../utils/logger');
const remoteDesktopService = require('./remoteDesktopService');
const MetricService = require('./metricService');

/**
 * Prepare the exam environment on the jumphost
 * 
 * This method executes the "prepare-exam-env" command on the jumphost
 * to set up the required number of nodes for the exam. It also updates
 * the exam status in Redis to reflect the preparation process.
 * 
 * @param {string} examId - The ID of the exam to prepare
 * @param {number} nodeCount - The number of nodes to prepare (default: 1)
 * @returns {Promise<Object>} Result object with success status and data
 */
async function setupExamEnvironment(examId, nodeCount = 1) {
  try {
    // Update exam status to PREPARING
    await redisClient.persistExamStatus(examId, 'PREPARING');
    logger.info(`Started preparing environment for exam ${examId} with ${nodeCount} nodes`);
    
    //restart vnc session
    await remoteDesktopService.restartVncSession();

    // Execute the prepare-exam-env command on the jumphost
    const command = `prepare-exam-env ${nodeCount} ${examId}`;
    
    logger.info(`Executing command on jumphost: ${command}`);
    const result = await sshService.executeCommand(command);
    
    logger.info('Command : prepare-exam-env, host: jumphost, result', { exitCode: result.exitCode });
    logger.info(result.stdout);

    if (result.exitCode !== 0) {
      logger.error('Failed to prepare exam environment', {
        stdout: result.stdout,
        stderr: result.stderr,
        exitCode: result.exitCode
      });
      
      await redisClient.persistExamStatus(examId, 'PREPARATION_FAILED');
      MetricService.sendMetrics(examId, {
        event: {
          examLabState: 'PREPARATION_FAILED'
        }
      });
      
      return {
        success: false,
        error: 'Failed to prepare exam environment',
        details: {
          stdout: result.stdout,
          stderr: result.stderr,
          exitCode: result.exitCode
        }
      };
    }
    
    // Update exam status to READY
    await redisClient.persistExamStatus(examId, 'READY');
    logger.info(`Successfully prepared environment for exam ${examId}`);
    MetricService.sendMetrics(examId, {
      event: {
        examLabState: 'READY'
      }
    });
    
    return {
      success: true,
      message: 'Exam environment prepared successfully',
      details: {
        stdout: result.stdout
      }
    };
  } catch (error) {
    logger.error('Error preparing exam environment', { error: error.message });
    
    // Update exam status to PREPARATION_FAILED
    await redisClient.persistExamStatus(examId, 'PREPARATION_FAILED');
    
    return {
      success: false,
      error: 'Error preparing exam environment',
      message: error.message
    };
  }
}

/**
 * Clean up the exam environment on the jumphost
 * 
 * This method executes the cleanup command on the jumphost to clean up
 * resources used by the exam. It also updates the exam status in Redis.
 * 
 * @param {string} examId - The ID of the exam to clean up
 * @returns {Promise<Object>} Result object with success status and data
 */
async function cleanupExamEnvironment(examId) {
  try {
    // Update exam status to CLEANING_UP
    await redisClient.persistExamStatus(examId, 'CLEANING_UP');
    logger.info(`Started cleaning up environment for exam ${examId}`);

    // Execute the cleanup command on the jumphost
    // Assuming a cleanup script exists on the jumphost
    const command = 'cleanup-exam-env';
    
    logger.info(`Executing command on jumphost: ${command}`);
    const result = await sshService.executeCommand(command);

    logger.info('Command : cleanup-exam-env, host: jumphost, result', { exitCode: result.exitCode });
    logger.info(result.stdout);


    if (result.exitCode !== 0) {
      logger.error('Failed to clean up exam environment', {
        stdout: result.stdout,
        stderr: result.stderr,
        exitCode: result.exitCode
      });

      MetricService.sendMetrics(examId, {
        event: {
          cleanupLabState: 'CLEANUP_FAILED'
        }
      });
      
      await redisClient.persistExamStatus(examId, 'CLEANUP_FAILED');
      
      return {
        success: false,
        error: 'Failed to clean up exam environment',
        details: {
          stdout: result.stdout,
          stderr: result.stderr,
          exitCode: result.exitCode
        }
      };
    }
    
    // Update exam status to COMPLETED
    await redisClient.persistExamStatus(examId, 'COMPLETED');
    logger.info(`Successfully cleaned up environment for exam ${examId}`);
    MetricService.sendMetrics(examId, {
      event: {
        cleanupLabState: 'COMPLETED'
      }
    });
    return {
      success: true,
      message: 'Exam environment cleaned up successfully',
      details: {
        stdout: result.stdout
      }
    };
  } catch (error) {
    logger.error('Error cleaning up exam environment', { error: error.message });
    
    // Update exam status to CLEANUP_FAILED
    await redisClient.persistExamStatus(examId, 'CLEANUP_FAILED');
    
    return {
      success: false,
      error: 'Error cleaning up exam environment',
      message: error.message
    };
  }
}

/**
 * Evaluate exam by running verification scripts on jumphost
 * 
 * This method executes verification scripts for each question and its steps
 * to validate student solutions. It updates the exam status during evaluation
 * and stores the final results in Redis.
 * 
 * @param {string} examId - The ID of the exam to evaluate
 * @param {Array} questions - Array of questions with verification steps
 * @returns {Promise<Object>} Result object with evaluation data
 */
async function evaluateExamOnJumphost(examId, questions) {
  try {
    let totalScore = 0;
    let totalPossibleScore = 0;
    const evaluationResults = [];

    //log number of questions 
    logger.info(`Number of questions to evaluate: ${questions.length}`);
    
    // Process each question
    for (const question of questions) {
      logger.info(`Evaluating question ${question.id}`);
      const questionResult = {
        id: question.id,
        namespace: question.namespace,
        question: question.question,
        concepts: question.concepts || [],
        domain: question.domain || null,
        verificationResults: []
      };

      // log info about question 
      logger.info(`Question ID: ${question.id}`);
      logger.info(`Namespace: ${question.namespace}`);
      logger.info(`Question: ${question.question}`);
      logger.info(`Concepts: ${question.concepts ? question.concepts.join(', ') : 'None'}`);
      // Process verification steps for the question
      for (const verification of question.verification) {
        const verificationScript = verification.verificationScriptFile;
        const weightage = parseInt(verification.weightage, 10);
        totalPossibleScore += weightage;

        try {
          // Execute the verification script directly using sshService
          // The script is located on the jumphost at the specified path
          const scriptPath = `/tmp/exam-assets/scripts/validation/${verificationScript}`;
          
          // Add KUBECONFIG environment variable to ensure all verifications use the correct kube config
          const commandWithKubeconfig = `export KUBECONFIG=/home/candidate/.kube/kubeconfig && ${scriptPath}`;
          
          logger.info(`Executing verification script: ${scriptPath} with KUBECONFIG set`);
          const result = await sshService.executeCommand(commandWithKubeconfig);
          
          // Determine if the verification passed
          const isValid = result.exitCode === 0;
          const score = isValid ? weightage : 0;
          totalScore += score;

          // Log info about verification
          logger.info(`Verification ID: ${verification.id}`);
          logger.info(`Description: ${verification.description}`);
          logger.info(`Weightage: ${weightage}`);
          logger.info(`Script Path: ${scriptPath}`);


          // Record the verification result without logs
          questionResult.verificationResults.push({
            id: verification.id,
            description: verification.description,
            validAnswer: isValid,
            weightage: weightage,
            score: score
          });

          // Log the result for debugging but don't include in response
          // Only include stderr in logs when exit code is 1 (failed verification)
          const logData = {
            stdout: result.stdout,
            exitCode: result.exitCode
          };
          
          // Only include stderr in logs when verification fails
          if (result.exitCode !== 0) {
            logData.stderr = result.stderr;
          }
          
          logger.info(`Verification ${verification.id} for question ${question.id}: ${isValid ? 'PASSED' : 'FAILED'}`, logData);
        } catch (error) {
          logger.error(`Error executing verification script for question ${question.id}`, { 
            error: error.message, verification: verification.id 
          });
          
          // Record the failed verification without error details
          questionResult.verificationResults.push({
            id: verification.id,
            description: verification.description,
            validAnswer: false,
            weightage: weightage,
            score: 0
          });
        }
      }

      console.log("################ question" + question.id + "done")
      // Add the question result to the evaluation results
      evaluationResults.push(questionResult);
    }

    // Calculate percentage score
    const percentageScore = totalPossibleScore > 0 ? 
      Math.round((totalScore / totalPossibleScore) * 100) : 0;

    // Assign rank based on percentage score
    let rank = 'low';
    if (percentageScore >= 80) {
      rank = 'high';
    } else if (percentageScore >= 60) {
      rank = 'medium';
    }

    // Prepare final evaluation result
    const finalResult = {
      examId,
      status: 'EVALUATED',
      totalScore,
      totalPossibleScore,
      percentageScore,
      rank,
      evaluationResults,
      completedAt: new Date().toISOString()
    };

    // Store result in Redis using the new persistExamResult method
    await redisClient.persistExamResult(examId, finalResult);
    
    // Update exam status to EVALUATED
    await redisClient.updateExamStatus(examId, 'EVALUATED');
    
    logger.info(`Exam ${examId} evaluation completed with score: ${percentageScore}%`);
    
    MetricService.sendMetrics(examId, {
      event: {
        examEvaluationState: 'EVALUATED',
        data:{
          totalScore,
          percentageScore,
        }
      }
    });

    return {
      success: true,
      data: finalResult
    };
  } catch (error) {
    logger.error(`Error in exam evaluation for exam ${examId}`, { error: error.message });
    // Update exam status to EVALUATION_FAILED
    await redisClient.updateExamStatus(examId, 'EVALUATION_FAILED');

    MetricService.sendMetrics(examId, {
      event: {
        examEvaluationState: 'EVALUATION_FAILED',
      }
    });
    return {
      success: false,
      error: 'Evaluation failed',
      message: error.message
    };
  }
}

module.exports = {
  setupExamEnvironment,
  cleanupExamEnvironment,
  evaluateExamOnJumphost
}; 