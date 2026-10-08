document.addEventListener('DOMContentLoaded', function() {
    const pageLoader = document.getElementById('pageLoader');
    const loaderMessage = document.getElementById('loaderMessage');
    // The exam picker is now the page itself; keep a tiny shim for code paths that used the old modal
    const examSelectionModal = {
        show() { document.getElementById('labList').scrollIntoView({ behavior: 'smooth', block: 'start' }); },
        hide() {}
    };
    const activeExamBanner = document.getElementById('activeExamBanner');
    const pickerSelection = document.getElementById('pickerSelection');
    
    // Form elements
    const categoryTabs = document.getElementById('examCategoryTabs');
    const labList = document.getElementById('labList');
    const startSelectedExamBtn = document.getElementById('startSelectedExam');
    const viewPastResultsBtn = document.getElementById('viewPastResultsBtn');
    
    // Hide View Results button by default - only show when current exam is EVALUATING or EVALUATED
    if (viewPastResultsBtn) {
        viewPastResultsBtn.closest('li').style.display = 'none';
    }
    
    let labs = []; // Will store all labs fetched from the API
    let selectedLab = null; // Will store the currently selected lab
    
    // Check for current exam status on page load
    checkCurrentExamStatus();
    
    console.log('Loading labs on page load...');
    // Load labs data when the page loads
    fetchLabs(false);

    // Function to check current exam status
    function checkCurrentExamStatus() {
        fetch('/facilitator/api/v1/exams/current')
            .then(response => {
                if (!response.ok) {
                    if (response.status !== 404) {
                        console.error('Error checking current exam status:', response.status);
                    }
                    return null;
                }
                return response.json();
            })
            .then(data => {
                if (data && data.id) {
                    // Store current exam data in localStorage for the View Results functionality
                    localStorage.setItem('currentExamData', JSON.stringify(data));
                    
                    // Show View Results button only if status is EVALUATING or EVALUATED
                    if (data.status === 'EVALUATING' || data.status === 'EVALUATED') {
                        if (viewPastResultsBtn) {
                            viewPastResultsBtn.closest('li').style.display = 'block';
                        }
                    }
                    showActiveExamBanner(data);
                    
                    // If exam is in PREPARING state, show loading overlay and start polling
                    if (data.status === 'PREPARING') {
                        console.log('Exam is in PREPARING state, showing loading overlay');
                        showLoadingOverlay();
                        updateLoadingMessage('Preparing lab environment...');
                        updateExamInfo(data.info?.name || 'Unknown Exam');
                        // Start polling for status
                        pollExamStatus(data.id).then(statusData => {
                            if (statusData.status === 'READY') {
                                // Redirect to exam page when ready
                                window.location.href = `/exam.html?id=${data.id}`;
                            }
                        });
                    }
                }
            })
            .catch(error => {
                console.error('Error checking current exam status:', error);
            });
    }

    // Banner above the picker for an exam that is still running or was just graded
    function showActiveExamBanner(data) {
        if (!activeExamBanner) return;
        const name = (data.info && data.info.name) || 'Current exam';
        const link = document.getElementById('continueExamLink');
        document.getElementById('activeExamName').textContent = name;
        if (data.status === 'READY') {
            link.textContent = 'Continue';
            link.href = `/exam.html?id=${data.id}`;
        } else if (data.status === 'EVALUATING' || data.status === 'EVALUATED') {
            activeExamBanner.querySelector('strong').textContent = 'Last exam:';
            link.textContent = 'View results';
            link.href = `/results?id=${data.id}`;
        } else {
            return;
        }
        activeExamBanner.hidden = false;
    }

    // Start button: make sure no other exam is active before launching the selected lab
    startSelectedExamBtn.addEventListener('click', function() {
        if (!selectedLab) return;
        fetch('/facilitator/api/v1/exams/current')
            .then(response => {
                if (response.status === 404) {
                    launchSelectedLab();
                    return null;
                }
                if (!response.ok) {
                    console.error('Error checking current exam status:', response.status);
                    launchSelectedLab();
                    return null;
                }
                return response.json();
            })
            .then(data => {
                if (data && data.id) {
                    showActiveExamWarningModal(data);
                } else if (data) {
                    launchSelectedLab();
                }
            })
            .catch(error => {
                console.error('Error checking for active exam:', error);
                launchSelectedLab();
            });
    });

    // Function to show warning modal for active exam
    function showActiveExamWarningModal(examData) {
        // Create modal HTML
        const modalHTML = `
            <div class="modal fade" id="activeExamWarningModal" tabindex="-1" aria-labelledby="activeExamWarningModalLabel" aria-hidden="true">
                <div class="modal-dialog modal-dialog-centered">
                    <div class="modal-content rounded">
                        <div class="modal-header bg-dark text-white rounded-top">
                            <h5 class="modal-title text-white" id="activeExamWarningModalLabel">Active Exam Detected</h5>
                            <button type="button" class="btn-close btn-close-white" data-bs-dismiss="modal" aria-label="Close"></button>
                        </div>
                        <div class="modal-body">
                            <div class="alert alert-info">
                                <p>You already have an active exam session:</p>
                                <p><strong>${examData.info?.name || 'Unknown Exam'}</strong></p>
                                <p class="mb-0">Only one active exam session can be present at a time.</p>
                            </div>
                        </div>
                        <div class="modal-footer rounded-bottom">
                            <button type="button" class="btn btn-sm btn-primary" id="continueSessionBtn">CONTINUE CURRENT SESSION</button>
                            <button type="button" class="btn btn-sm btn-danger" id="terminateAndProceedBtn">TERMINATE AND PROCEED</button>
                        </div>
                    </div>
                </div>
            </div>
        `;
        
        // Add modal to DOM if it doesn't exist
        if (!document.getElementById('activeExamWarningModal')) {
            document.body.insertAdjacentHTML('beforeend', modalHTML);
        }
        
        // Get modal element and create Bootstrap modal
        const modalElement = document.getElementById('activeExamWarningModal');
        const warningModal = new bootstrap.Modal(modalElement);
        
        // Show the modal
        warningModal.show();
        
        // Remove any existing event listeners by cloning and replacing the buttons
        const oldTerminateBtn = document.getElementById('terminateAndProceedBtn');
        const newTerminateBtn = oldTerminateBtn.cloneNode(true);
        oldTerminateBtn.parentNode.replaceChild(newTerminateBtn, oldTerminateBtn);
        
        const oldContinueBtn = document.getElementById('continueSessionBtn');
        const newContinueBtn = oldContinueBtn.cloneNode(true);
        oldContinueBtn.parentNode.replaceChild(newContinueBtn, oldContinueBtn);
        
        // Add event listener for continue session button
        document.getElementById('continueSessionBtn').addEventListener('click', function() {
            // Redirect to the current exam
            window.location.href = `/exam.html?id=${examData.id}`;
        });
        
        // Add event listener for terminate and proceed button
        document.getElementById('terminateAndProceedBtn').addEventListener('click', function() {
            // Update button to show progress
            const terminateBtn = document.getElementById('terminateAndProceedBtn');
            terminateBtn.disabled = true;
            terminateBtn.innerHTML = '<div class="d-flex align-items-center justify-content-center"><span class="spinner-border spinner-border-sm me-2" role="status" aria-hidden="true"></span><span>TERMINATING...</span></div>';
            
            // Show loading overlay
            showLoadingOverlay();
            updateLoadingMessage('Terminating active session...');
            
            console.log('Attempting to terminate exam:', examData.id);
            // Call API to terminate the active exam
            fetch(`/facilitator/api/v1/exams/${examData.id}/terminate`, {
                method: 'POST'
            })
            .then(response => {
                if (!response.ok) {
                    console.error('Termination failed with status:', response.status);
                    throw new Error('Failed to terminate exam. Status: ' + response.status);
                }
                return response.json();
            })
            .then((data) => {
                console.log('Exam terminated successfully:', examData.id);
                // Hide the warning modal
                warningModal.hide();
                
                // Clear any stored exam data
                localStorage.removeItem('currentExamData');
                localStorage.removeItem('currentExamId');
                
                // Proceed with the lab picked on the page
                hideLoadingOverlay();
                if (activeExamBanner) activeExamBanner.hidden = true;
                launchSelectedLab();
            })
            .catch(error => {
                console.error('Error terminating exam:', error);
                hideLoadingOverlay();
                
                // Reset button state
                terminateBtn.disabled = false;
                terminateBtn.innerHTML = 'Terminate and Proceed';
                
                alert('Failed to terminate the active exam. Please try again later.');
            });
            
            // Clean up the modal when it's hidden
            modalElement.addEventListener('hidden.bs.modal', function() {
                console.log('Modal hidden, cleaning up event listeners');
                
                // Remove event listeners by replacing buttons with clones if they exist
                if (document.getElementById('terminateAndProceedBtn')) {
                    const oldTerminateBtn = document.getElementById('terminateAndProceedBtn');
                    const newTerminateBtn = oldTerminateBtn.cloneNode(true);
                    oldTerminateBtn.parentNode.replaceChild(newTerminateBtn, oldTerminateBtn);
                }
                
                if (document.getElementById('continueSessionBtn')) {
                    const oldContinueBtn = document.getElementById('continueSessionBtn');
                    const newContinueBtn = oldContinueBtn.cloneNode(true);
                    oldContinueBtn.parentNode.replaceChild(newContinueBtn, oldContinueBtn);
                }
            });
        });
    }
    
    // Fetch labs from the facilitator API
    function fetchLabs(showLoader = true) {
        console.log('Fetching labs, showLoader:', showLoader);
        if (showLoader) {
            pageLoader.style.display = 'flex';
            loaderMessage.textContent = 'Loading labs...';
        }
        
        fetch('/facilitator/api/v1/assements/')
            .then(response => {
                if (!response.ok) {
                    throw new Error('Failed to fetch labs. Status: ' + response.status);
                }
                return response.json();
            })
            .then(data => {
                labs = data;
                console.log('Labs loaded successfully, count:', labs.length);
                if (showLoader) {
                    pageLoader.style.display = 'none';
                }
                populateLabCategories();
            })
            .catch(error => {
                console.error('Error fetching labs:', error);
                if (showLoader) {
                    pageLoader.style.display = 'none';
                }
                labList.innerHTML = '<div class="text-danger small">Could not load the exams. Is the facilitator running? Reload the page to retry.</div>';
            });
    }
    
    // Display names and order for certification categories
    const CATEGORY_INFO = {
        CKA:   'CKA - Kubernetes Administrator',
        CKAD:  'CKAD - Application Developer',
        CKS:   'CKS - Security Specialist',
        KCNA:  'KCNA - Cloud Native Associate',
        KCSA:  'KCSA - Cloud Native Security Associate',
        Other: 'Other'
    };
    const CATEGORY_ORDER = Object.keys(CATEGORY_INFO);
    let activeCategory = null;

    function escapeHtml(text) {
        const div = document.createElement('div');
        div.textContent = text == null ? '' : String(text);
        return div.innerHTML;
    }

    function savedCategory() {
        try { return localStorage.getItem('ckx_last_category'); } catch (e) { return null; }
    }

    // Build one tab per category that actually has labs
    function populateLabCategories() {
        const categories = [...new Set(labs.map(lab => lab.category))].sort((a, b) => {
            const ia = CATEGORY_ORDER.indexOf(a), ib = CATEGORY_ORDER.indexOf(b);
            return (ia === -1 ? 99 : ia) - (ib === -1 ? 99 : ib);
        });
        categoryTabs.innerHTML = '';
        categories.forEach(category => {
            const count = labs.filter(lab => lab.category === category).length;
            const tab = document.createElement('button');
            tab.type = 'button';
            tab.className = 'category-tab';
            tab.setAttribute('role', 'tab');
            tab.dataset.category = category;
            tab.title = CATEGORY_INFO[category] || category;
            tab.innerHTML = `${escapeHtml(category)} <span class="category-count">${count}</span>`;
            tab.addEventListener('click', () => selectCategory(category));
            categoryTabs.appendChild(tab);
        });
        const preferred = savedCategory();
        const initial = categories.includes(activeCategory) ? activeCategory
            : categories.includes(preferred) ? preferred
            : categories.includes('CKA') ? 'CKA' : categories[0];
        if (initial) {
            selectCategory(initial);
        } else {
            labList.innerHTML = '<div class="text-muted small">No exams available.</div>';
        }
    }

    function selectCategory(category) {
        activeCategory = category;
        try { localStorage.setItem('ckx_last_category', category); } catch (e) { /* ignore */ }
        categoryTabs.querySelectorAll('.category-tab').forEach(tab => {
            const active = tab.dataset.category === category;
            tab.classList.toggle('active', active);
            tab.setAttribute('aria-selected', active ? 'true' : 'false');
        });
        renderLabList(category);
    }

    function difficultyClass(difficulty) {
        const d = (difficulty || 'Medium').toLowerCase();
        return d === 'easy' ? 'easy' : d === 'hard' ? 'hard' : 'medium';
    }

    // Render the labs of a category as selectable cards
    function renderLabList(category) {
        const filteredLabs = labs.filter(lab => lab.category === category)
            .sort((a, b) => String(a.id).localeCompare(String(b.id), undefined, { numeric: true }));
        labList.innerHTML = '';
        selectedLab = null;
        startSelectedExamBtn.disabled = true;
        if (pickerSelection) pickerSelection.textContent = 'No exam selected';

        if (filteredLabs.length === 0) {
            labList.innerHTML = '<div class="text-muted small">No exams available for this certification.</div>';
            return;
        }

        filteredLabs.forEach(lab => {
            const difficulty = lab.difficulty || 'Medium';
            const minutes = lab.examDurationInMinutes || lab.estimatedTime || 30;
            const card = document.createElement('button');
            card.type = 'button';
            card.className = 'lab-card';
            card.setAttribute('role', 'radio');
            card.setAttribute('aria-checked', 'false');
            card.dataset.labId = lab.id;
            card.title = lab.description || '';
            card.innerHTML = `
                <div class="lab-card-head">
                    <span class="lab-card-title">${escapeHtml(lab.name)}</span>
                    <span class="lab-card-check" aria-hidden="true"><i class="fas fa-check"></i></span>
                </div>
                <p class="lab-card-desc">${escapeHtml(lab.description || 'No description available.')}</p>
                <div class="lab-card-meta">
                    <span class="lab-badge ${difficultyClass(difficulty)}">${escapeHtml(difficulty)}</span>
                    <span><i class="far fa-clock me-1"></i>${escapeHtml(minutes)} min</span>
                </div>`;
            card.addEventListener('click', () => selectLab(lab.id));
            card.addEventListener('dblclick', () => { selectLab(lab.id); startSelectedExamBtn.click(); });
            labList.appendChild(card);
        });

        selectLab(filteredLabs[0].id);
    }

    function selectLab(labId) {
        const lab = labs.find(l => l.id === labId);
        if (!lab) return;
        selectedLab = lab;
        labList.querySelectorAll('.lab-card').forEach(card => {
            const active = card.dataset.labId === labId;
            card.classList.toggle('selected', active);
            card.setAttribute('aria-checked', active ? 'true' : 'false');
        });
        startSelectedExamBtn.disabled = false;
        if (pickerSelection) {
            pickerSelection.textContent = `${lab.name} · ${lab.examDurationInMinutes || 30} min`;
        }
    }

    // Create the exam for the selected lab and wait until the environment is ready
    function launchSelectedLab() {
        if (selectedLab) {
            examSelectionModal.hide();
            showLoadingOverlay(); // Show the loading overlay instead of pageLoader
            updateLoadingMessage('Starting lab environment...');
            updateExamInfo(`Lab: ${selectedLab.name} | Difficulty: ${selectedLab.difficulty || 'Medium'}`);
            let userAgent = '';
            try {
                userAgent = navigator.userAgent;
            } catch (error) {
                console.error('Error getting user agent:', error);
            }
            selectedLab.userAgent = userAgent;
            
            // Make a POST request to the facilitator API - using exams endpoint for POST
            fetch('/facilitator/api/v1/exams/', {
                method: 'POST',
                headers: {
                    'Content-Type': 'application/json'
                },
                body: JSON.stringify(selectedLab)
            })
            .then(response => {
                if (!response.ok) {
                    throw new Error('Failed to start lab. Status: ' + response.status);
                }
                return response.json();
            })
            .then(data => {
                // Store exam ID in localStorage
                localStorage.setItem('currentExamId', data.id);
                
                // Start polling for status
                const warmUpTime = data.warmUpTimeInSeconds || 30;
                updateLoadingMessage(`Preparing your lab environment (${warmUpTime}s estimated)`);
                
                // Poll for exam status until it's ready
                return pollExamStatus(data.id);
            })
            .then(() => {
                // Redirect to the lab page after status is READY
                const examId = localStorage.getItem('currentExamId');
                window.location.href = `/exam.html?id=${examId}`;
            })
            .catch(error => {
                console.error('Error starting lab:', error);
                hideLoadingOverlay();
                alert('Failed to start the lab. Please try again later.');
            });
        }
    }

    // Add new functions for exam status handling
    function showLoadingOverlay() {
        document.getElementById('loadingOverlay').style.display = 'flex';
    }

    function hideLoadingOverlay() {
        document.getElementById('loadingOverlay').style.display = 'none';
    }

    function updateProgressBar(progress) {
        document.getElementById('progressBar').style.width = `${progress}%`;
    }

    function updateLoadingMessage(message) {
        document.getElementById('loadingMessage').textContent = message;
    }

    function updateExamInfo(info) {
        document.getElementById('examInfo').textContent = info;
    }

    async function pollExamStatus(examId) {
        const startTime = Date.now();
        const pollInterval = 1000; // Poll every 1 second
        
        return new Promise((resolve, reject) => {
            const poll = async () => {
                try {
                    const response = await fetch(`/facilitator/api/v1/exams/${examId}/status`);
                    const data = await response.json();
                    
                    // set warmup time in seconds
                    const warmUpTimeInSeconds = data.warmUpTimeInSeconds || 30;

                    if (data.status === 'READY') {
                        // Set progress to 100% when ready
                        updateProgressBar(100);
                        updateLoadingMessage('Lab environment is ready! Redirecting...');
                        // Wait a moment for the user to see the 100% progress
                        setTimeout(() => resolve(data), 1000);
                        return;
                    }
                    
                    // Calculate progress based on warm-up time
                    const elapsedTime = (Date.now() - startTime) / 1000;
                    const progress = Math.min((elapsedTime / warmUpTimeInSeconds) * 100, 95);
                    updateProgressBar(progress);
                    updateLoadingMessage(data.message || 'Preparing lab environment...');
                    
                    // Continue polling
                    setTimeout(poll, pollInterval);
                } catch (error) {
                    console.error('Error polling exam status:', error);
                    // Show error in the loading overlay
                    updateLoadingMessage(`Error: ${error.message}. Retrying...`);
                    // Continue polling despite errors
                    setTimeout(poll, pollInterval);
                }
            };
            
            poll();
        });
    }

    // Modify the existing startExam function
    async function startExam(examId) {
        try {
            showLoadingOverlay();
            updateLoadingMessage('Starting exam environment...');
            
            const response = await fetch('/facilitator/api/v1/exams', {
                method: 'POST',
                headers: {
                    'Content-Type': 'application/json'
                },
                body: JSON.stringify({ examId })
            });
            
            const data = await response.json();
            
            if (!response.ok) {
                throw new Error(data.message || 'Failed to start exam');
            }
            
            // Store exam ID in localStorage
            localStorage.setItem('currentExamId', data.id);
            
            // Start polling for status
            await pollExamStatus(data.id, data.warmUpTimeInSeconds || 30);
            
            // Redirect to exam page when ready
            window.location.href = `/exam.html?id=${data.id}`;
        } catch (error) {
            console.error('Error starting exam:', error);
            hideLoadingOverlay();
            alert('Failed to start exam: ' + error.message);
        }
    }

    // Modify the dropdown population to include difficulty info
    function populateDropdown(labs) {
        const dropdown = document.getElementById('examDropdown');
        dropdown.innerHTML = '';
        
        labs.forEach(lab => {
            const option = document.createElement('option');
            option.value = lab.id;
            option.textContent = `${lab.name} (${lab.difficulty || 'Medium'})`;
            option.title = `${lab.description}\nDifficulty: ${lab.difficulty || 'Medium'}\nEstimated Time: ${lab.estimatedTime || '30'} minutes`;
            dropdown.appendChild(option);
        });
    }

    // Add event listener for View Past Results button
    viewPastResultsBtn.addEventListener('click', function() {
        // Check if we have current exam data
        const currentExamDataStr = localStorage.getItem('currentExamData');
        
        if (currentExamDataStr) {
            try {
                const currentExamData = JSON.parse(currentExamDataStr);
                
                // If the current exam is evaluated or being evaluated, go directly to results
                if (currentExamData.status === 'EVALUATED' || currentExamData.status === 'EVALUATING') {
                    window.location.href = `/results?id=${currentExamData.id}`;
                    return;
                } else {
                    // If the exam exists but isn't in the right state, show an alert
                    alert('Exam results are not available yet. The exam must be evaluated first.');
                    return;
                }
            } catch (error) {
                console.error('Error parsing current exam data:', error);
            }
        }
        
        // If there's no current exam at all, inform the user
        alert('No active exam found. Please start an exam first.');
    });
}); 