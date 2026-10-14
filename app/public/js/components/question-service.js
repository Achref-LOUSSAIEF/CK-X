/**
 * Question Service
 * Handles question display and navigation
 */

// Process question content to improve formatting and highlighting
function processQuestionContent(content) {
    // First, preserve existing HTML formatting
    let processedContent = content;
    
    // Add highlighting to text in single quotes that isn't already styled
    processedContent = processedContent.replace(
        /`([^`]+)`/g, 
        function(match, text) {
            // Skip if already inside an HTML tag or existing styled element
            if (match.match(/<.*>/) || 
                match.includes('class="code"') || 
                match.includes('class="highlight"')) {
                return match;
            }
            return `<span class="inline-code">${text}</span>`;
        }
    );
    
    // Style inline code with backticks if not already styled
    processedContent = processedContent.replace(
        /`([^`]+)`/g, 
        '<code class="bg-light px-1 rounded">$1</code>'
    );
    
    // Style bold text
    processedContent = processedContent.replace(
        /\*\*([^*]+)\*\*/g, 
        '<strong>$1</strong>'
    );
    
    // Style italic text
    processedContent = processedContent.replace(
        /\*([^*]+)\*/g, 
        '<em>$1</em>'
    );
    
    // Convert literal newline characters to HTML line breaks
    processedContent = processedContent.replace(/\n/g, '<br>');
    
    // Ensure paragraphs have proper spacing and line breaks
    processedContent = processedContent.replace(
        /<\/p><p>/g, 
        '</p>\n<p>'
    );
    
    // Add more spacing between list items
    processedContent = processedContent.replace(
        /<\/li><li>/g, 
        '</li>\n<li>'
    );
    
    return processedContent;
}

// Generate question content HTML
function generateQuestionContent(question) {
    try {
        // Get original data
        const originalData = question.originalData || {};
        const machineHostname = originalData.machineHostname || 'N/A';
        const namespace = originalData.namespace || 'N/A';
        
        // Format question content with improved styling
        const formattedQuestionContent = processQuestionContent(question.content);

        // Task-specific documentation, like the Quick Reference box of the real exam.
        // The links are meant to be opened in the exam desktop's Firefox, which allows them.
        const esc = (text) => String(text).replace(/[&<>"']/g, (c) => ({ '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;', "'": '&#39;' }[c]));
        const quickReference = Array.isArray(originalData.quickReference) ? originalData.quickReference : [];
        const quickReferenceHtml = quickReference.length === 0 ? '' : `
                    <div class="mb-3 quick-reference">
                        <strong>Quick Reference</strong> <span class="text-muted small">(open in the exam desktop's Firefox)</span>
                        <ul class="mb-0 mt-1">
                            ${quickReference.map((ref) => `<li>${esc(ref.title)}: <span class="inline-code user-select-all">${esc(ref.url)}</span></li>`).join('')}
                        </ul>
                    </div>`;
        
        // Create formatted content with minimal layout
        return `
            <div class="d-flex flex-column" style="height: 100%;">
                <div class="question-header">
                    
                    <div class="mb-3">
                        <strong>Solve this question on instance:</strong> <span class="inline-code">ssh ${machineHostname}</span></span>
                    </div>
                    
                    <div class="mb-3">
                        <strong>Namespace:</strong> <span class="text-primary">${namespace}</span>
                    </div>
                    ${quickReferenceHtml}
                    
                    <hr class="my-3">
                </div>
                
                <div class="question-body">
                    ${formattedQuestionContent}
                </div>
                
                <div class="action-buttons-container mt-auto">
                    <div class="d-flex justify-content-between py-2">
                        <button class="btn ${question.flagged ? 'btn-warning' : 'btn-outline-warning'}" id="flagQuestionBtn">
                            <svg xmlns="http://www.w3.org/2000/svg" width="16" height="16" fill="currentColor" class="bi bi-flag${question.flagged ? '-fill' : ''} me-2" viewBox="0 0 16 16">
                                <path d="M14.778.085A.5.5 0 0 1 15 .5V8a.5.5 0 0 1-.314.464L14.5 8l.186.464-.003.001-.006.003-.023.009a12.435 12.435 0 0 1-.397.15c-.264.095-.631.223-1.047.35-.816.252-1.879.523-2.71.523-.847 0-1.548-.28-2.158-.525l-.028-.01C7.68 8.71 7.14 8.5 6.5 8.5c-.7 0-1.638.23-2.437.477A19.626 19.626 0 0 0 3 9.342V15.5a.5.5 0 0 1-1 0V.5a.5.5 0 0 1 1 0v.282c.226-.079.496-.17.79-.26C4.606.272 5.67 0 6.5 0c.84 0 1.524.277 2.121.519l.043.018C9.286.788 9.828 1 10.5 1c.7 0 1.638-.23 2.437-.477a19.587 19.587 0 0 0 1.349-.476l.019-.007.004-.002h.001"/>
                            </svg>
                            ${question.flagged ? 'Flagged' : 'Flag for review'}
                        </button>
                        <button class="btn btn-success" id="nextQuestionBtn">
                            Satisfied with answer
                            <svg xmlns="http://www.w3.org/2000/svg" width="16" height="16" fill="currentColor" class="bi bi-arrow-right ms-2" viewBox="0 0 16 16">
                                <path fill-rule="evenodd" d="M1 8a.5.5 0 0 1 .5-.5h11.793l-3.147-3.146a.5.5 0 0 1 .708-.708l4 4a.5.5 0 0 1 0 .708l-4 4a.5.5 0 0 1-.708-.708L13.293 8.5H1.5A.5.5 0 0 1 1 8z"/>
                            </svg>
                        </button>
                    </div>
                </div>
            </div>
        `;
    } catch (error) {
        console.error('Error generating question content:', error);
        return '<div class="alert alert-danger">Error displaying question content. Please try refreshing the page.</div>';
    }
}

// Transform API response to question objects
function transformQuestionsFromApi(data) {
    if (data.questions && Array.isArray(data.questions)) {
        // Transform the questions to match our expected format
        return data.questions.map(q => ({
            id: q.id,
            content: q.question || '', // Map 'question' field to 'content'
            title: `Question ${q.id}`,  // Create a title from the ID
            originalData: q, // Keep original data for reference if needed
            flagged: false // Add flagged status property
        }));
    }
    return [];
}

// Update question dropdown
function updateQuestionDropdown(questionsArray, dropdownMenu, currentId, onQuestionSelect) {
    // Clear existing dropdown items
    dropdownMenu.innerHTML = '';
    
    // Add items for each question
    questionsArray.forEach((question) => {
        const li = document.createElement('li');
        const a = document.createElement('a');
        a.className = 'dropdown-item';
        a.href = '#';
        a.dataset.question = question.id;
        a.textContent = `Question ${question.id}`;
        
        // Add flag icon if question is flagged
        if (question.flagged) {
            const flagIcon = document.createElement('span');
            flagIcon.className = 'flag-icon ms-2';
            flagIcon.innerHTML = '<svg xmlns="http://www.w3.org/2000/svg" width="12" height="12" fill="currentColor" class="bi bi-flag-fill text-warning" viewBox="0 0 16 16"><path d="M14.778.085A.5.5 0 0 1 15 .5V8a.5.5 0 0 1-.314.464L14.5 8l.186.464-.003.001-.006.003-.023.009a12.435 12.435 0 0 1-.397.15c-.264.095-.631.223-1.047.35-.816.252-1.879.523-2.71.523-.847 0-1.548-.28-2.158-.525l-.028-.01C7.68 8.71 7.14 8.5 6.5 8.5c-.7 0-1.638.23-2.437.477A19.626 19.626 0 0 0 3 9.342V15.5a.5.5 0 0 1-1 0V.5a.5.5 0 0 1 1 0v.282c.226-.079.496-.17.79-.26C4.606.272 5.67 0 6.5 0c.84 0 1.524.277 2.121.519l.043.018C9.286.788 9.828 1 10.5 1c.7 0 1.638-.23 2.437-.477a19.587 19.587 0 0 0 1.349-.476l.019-.007.004-.002h.001"/></svg>';
            a.appendChild(flagIcon);
        }
        
        // Add click event
        a.addEventListener('click', function(e) {
            e.preventDefault();
            const clickedQuestionId = this.dataset.question;
            if (onQuestionSelect) {
                onQuestionSelect(clickedQuestionId);
            }
        });
        
        li.appendChild(a);
        dropdownMenu.appendChild(li);
    });
}

export {
    processQuestionContent,
    generateQuestionContent,
    transformQuestionsFromApi,
    updateQuestionDropdown
}; 