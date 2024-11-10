package main

import (
  "fmt"
  "log"
  "os"
  "strings"

  tea "github.com/charmbracelet/bubbletea"
  "github.com/charmbracelet/bubbles/textinput"
)

type model struct {
  step             int
  nameInput        textinput.Model
  emailInput       textinput.Model
  gpgQuestion      string
  gpgAnswer        string
  gpgSigningKey    textinput.Model
  respondedGPG     bool
  username         string
  email            string
  useGPG           bool
  signingKey       string
}

const (
  stepGitHubUsername = iota
  stepGitHubEmail
  stepGPGQuestion
  stepGPGKey
  stepComplete
)

func (m model) Init() tea.Cmd {
  return nil
}

func (m *model) Update(msg tea.Msg) (tea.Model, tea.Cmd) {
  switch m.step {
  case stepGitHubUsername:
    return m.updateGitHubUsername(msg)
  case stepGitHubEmail:
    return m.updateGitHubEmail(msg)
  case stepGPGQuestion:
    return m.updateGPGQuestion(msg)
  case stepGPGKey:
    return m.updateGPGKey(msg)
  case stepComplete:
    return m.handleComplete(msg)
  }
  return m, nil
}

// Handles the GitHub username input step
func (m *model) updateGitHubUsername(msg tea.Msg) (tea.Model, tea.Cmd) {
  var cmd tea.Cmd
  m.nameInput, cmd = m.nameInput.Update(msg)

  if m.nameInput.Value() != "" && isEnter(msg) {
    m.username = m.nameInput.Value() // Save the username
    m.step = stepGitHubEmail
    m.emailInput.Focus()
  }
  return m, cmd
}

// Handles the GitHub email input step
func (m *model) updateGitHubEmail(msg tea.Msg) (tea.Model, tea.Cmd) {
  var cmd tea.Cmd
  m.emailInput, cmd = m.emailInput.Update(msg)

  if m.emailInput.Value() != "" && isEnter(msg) {
    m.email = m.emailInput.Value() // Save the email
    m.step = stepGPGQuestion
  }
  return m, cmd
}

// Handles the GPG yes/no question
func (m *model) updateGPGQuestion(msg tea.Msg) (tea.Model, tea.Cmd) {
  if keyMsg, ok := msg.(tea.KeyMsg); ok {
    switch keyMsg.String() {
    case "y":
      m.useGPG = true
      m.step = stepGPGKey
      m.gpgSigningKey.Focus()
    case "n":
      m.useGPG = false
      m.step = stepComplete
    }
  }
  return m, nil
}

// Handles the GPG key input step
func (m *model) updateGPGKey(msg tea.Msg) (tea.Model, tea.Cmd) {
  var cmd tea.Cmd
  m.gpgSigningKey, cmd = m.gpgSigningKey.Update(msg)

  if m.gpgSigningKey.Value() != "" && isEnter(msg) {
    m.signingKey = m.gpgSigningKey.Value()
    m.step = stepComplete
  }
  return m, cmd
}

// Handle the final step and allow quitting
func (m *model) handleComplete(msg tea.Msg) (tea.Model, tea.Cmd) {
  if keyMsg, ok := msg.(tea.KeyMsg); ok {
    switch keyMsg.String() {
    case "q":
      return m, tea.Quit // Quit the program if the user presses 'q'
    case "ctrl+c":
      return m, tea.Quit // Quit the program if the user presses 'Ctrl+C'
    }
  }
  return m, nil
}

// Check if the key pressed is Enter
func isEnter(msg tea.Msg) bool {
  if keyMsg, ok := msg.(tea.KeyMsg); ok {
    return keyMsg.String() == "enter"
  }
  return false
}

func (m model) View() string {
  var view string

  switch m.step {
  case stepGitHubUsername:
    view = fmt.Sprintf("What is your GitHub username?\n\n%s", m.nameInput.View())
  case stepGitHubEmail:
    view = fmt.Sprintf("What is your GitHub email address?\n\n%s", m.emailInput.View())
  case stepGPGQuestion:
    view = fmt.Sprintf("Do you use GPG to sign your commits? (y/n)\n\n%s", m.gpgQuestion)
  case stepGPGKey:
    view = fmt.Sprintf("Enter your GPG signing key:\n\n%s", m.gpgSigningKey.View())
  case stepComplete:
    view = fmt.Sprintf("Thank you! You provided:\n\nUsername: %s\nEmail: %s\nUse GPG: %v\nSigning Key: %s\n\nPress 'q' to quit.", m.username, m.email, m.useGPG, m.signingKey)
  }

  return view
}

func main() {
  // Create the initial model with textinput components
  m := &model{
    nameInput:        textinput.New(),
    emailInput:       textinput.New(),
    gpgSigningKey:    textinput.New(),
    gpgQuestion:      "Please answer (y/n)",
    username:         "",
    email:            "",
    useGPG:           false,
    signingKey:       "",
    respondedGPG:     false,
  }

  // Configure the textinputs
  m.nameInput.Placeholder = "Enter your GitHub username"
  m.emailInput.Placeholder = "Enter your GitHub email address"
  m.gpgSigningKey.Placeholder = "Enter your GPG signing key (if applicable)"

  // Focus the name input at the start
  m.nameInput.Focus()

  // Set up logging to file
  f, err := tea.LogToFile("debug.log", "debug")
  if err != nil {
    log.Fatalf("Error setting up log file: %v", err)
  }
  defer f.Close()

  // Start the program with the model
  p := tea.NewProgram(m, tea.WithAltScreen())

  // Run the program
  if _, err := p.Run(); err != nil {
    log.Fatal(err)
  }

  // Once the wizard is complete, write to ~/.env
  if err := writeEnvFile(*m); err != nil {
    log.Fatal(err)
  }
}


func writeEnvFile(m model) error {
  // Determine the path to the .env file
  home, err := os.UserHomeDir()
  if err != nil {
    return fmt.Errorf("could not find home directory: %w", err)
  }
  envPath := home + "/.env"

  // Read the existing file contents, if it exists
  fileData, err := os.ReadFile(envPath)
  if err != nil && !os.IsNotExist(err) {
    return fmt.Errorf("could not read .env file: %w", err)
  }

  // Split the file data into lines
  lines := strings.Split(string(fileData), "\n")

  // Open the file for writing (truncate it to overwrite the entire content)
  file, err := os.OpenFile(envPath, os.O_RDWR|os.O_CREATE|os.O_TRUNC, 0755)
  if err != nil {
    return fmt.Errorf("could not open .env file: %w", err)
  }
  defer file.Close()

  // Remove any existing GITHUB_USERNAME, GITHUB_EMAIL, and GPG_SIGNING_KEY entries
  var newLines []string
  for _, line := range lines {
    // Skip lines that match the environment variables we are updating
    if strings.HasPrefix(line, "GITHUB_USERNAME=") ||
      strings.HasPrefix(line, "GITHUB_EMAIL=") ||
      strings.HasPrefix(line, "GPG_SIGNING_KEY=") {
      continue
    }
    newLines = append(newLines, line)
  }

  // Add the updated environment variables (without a trailing newline)
  if m.username != "" {
    newLines = append(newLines, fmt.Sprintf("GITHUB_USERNAME=%s", m.username))
  }
  if m.email != "" {
    newLines = append(newLines, fmt.Sprintf("GITHUB_EMAIL=%s", m.email))
  }
  if m.useGPG && m.signingKey != "" {
    newLines = append(newLines, fmt.Sprintf("GPG_SIGNING_KEY=%s", m.signingKey))
  }

  // Write everything back to the file (overwrite)
  for i, line := range newLines {
    // Don't add an extra newline after the last line
    if i == len(newLines)-1 {
      if _, err := file.WriteString(line); err != nil {
        return fmt.Errorf("could not write to .env file: %w", err)
      }
    } else {
      if _, err := file.WriteString(line + "\n"); err != nil {
        return fmt.Errorf("could not write to .env file: %w", err)
      }
    }
  }

  // Debug: Print the values to confirm they are being captured correctly
  fmt.Printf("Writing to .env:\nGITHUB_USERNAME=%s\nGITHUB_EMAIL=%s\nGPG_SIGNING_KEY=%s\n", m.username, m.email, m.signingKey)

  return nil
}
