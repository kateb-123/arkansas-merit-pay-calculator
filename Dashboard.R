library(shiny)
library(DT)
library(bslib)
library(dplyr)
library(readxl)

# Load data
geographic_data <- read_excel("data/geographic.xlsx")
subject_growth_data <- read_excel("data/subject_growth.xlsx")
grade_level_data <- read_excel("data/grade_level.xlsx")

ui <- fluidPage(
  theme = bs_theme(
    bg = "#f5f5f5",
    fg = "#1a1a1a",
    primary = "#00573F",
    base_font = c("Open Sans", "sans-serif"),
    heading_font = c("Merriweather", "serif")
  ),

  tags$style(HTML("
    .container-fluid { padding-left: 0 !important; padding-right: 0 !important; }
    .radio-inline { margin-right: 20px; }

    .main-content {
      max-width: 1100px;
      margin: 0 auto;
      padding: 0 28px;
      box-sizing: border-box;
    }
    .table-content {
      max-width: 1100px;
      margin: 0 auto;
      padding: 0;
    }
    .table-content .results-header { padding: 0 28px; }
    .table-content .bonus-cap-note { padding: 0 28px; }

    .section-card {
      background: #ffffff;
      border-radius: 6px;
      border: 1px solid #e2e2e2;
      padding: 18px 22px 10px 22px;
      margin-bottom: 14px;
      animation: fadeSlideIn 0.25s ease;
    }
    @keyframes fadeSlideIn {
      from { opacity: 0; transform: translateY(-8px); }
      to   { opacity: 1; transform: translateY(0); }
    }
    .section-label {
      font-size: 10px;
      font-weight: 800;
      text-transform: uppercase;
      letter-spacing: 0.09em;
      color: #999;
      margin-bottom: 10px;
    }
    .results-header {
      font-size: 10px;
      font-weight: 800;
      text-transform: uppercase;
      letter-spacing: 0.09em;
      color: #999;
      margin-bottom: 10px;
      margin-top: 8px;
    }

    .accordion-item {
      border: 1px solid #e2e2e2 !important;
      border-radius: 6px !important;
      margin-bottom: 10px !important;
      background-color: #ffffff;
      overflow: hidden;
    }
    .accordion-button {
      font-family: 'Open Sans', sans-serif !important;
      font-size: 10px !important;
      font-weight: 800 !important;
      text-transform: uppercase !important;
      letter-spacing: 0.09em !important;
      color: #999 !important;
      background-color: #ffffff !important;
      padding: 14px 18px !important;
      box-shadow: none !important;
    }
    .accordion-button:not(.collapsed) {
      color: #555 !important;
      background-color: #ffffff !important;
      box-shadow: none !important;
    }
    .accordion-button:focus { box-shadow: none !important; }
    .accordion-button::after { background-size: 12px !important; opacity: 0.4; }
    .accordion-body {
      padding: 2px 18px 16px 18px !important;
      font-size: 14px;
      color: #444;
      line-height: 1.7;
    }
    .accordion-body ul { padding-left: 18px; line-height: 1.9; margin-bottom: 0; }
    .accordion-body a { color: #00573F; text-decoration: none; }
    .accordion-body a:hover { text-decoration: underline; }
    .accordion-body p { margin-bottom: 8px; }
    .resource-links ul { list-style: none; padding-left: 0; line-height: 2.2; }

    .dataTable { width: 100% !important; }
    table.dataTable tbody td {
      padding: 14px 10px !important;
      text-align: left !important;
      vertical-align: top !important;
      border-top: none !important;
      border-bottom: 1px solid #f0f0f0 !important;
    }
    table.dataTable thead th {
      text-align: left !important;
      vertical-align: top !important;
      font-size: 14px !important;
      font-weight: 700 !important;
      color: #555 !important;
      border-bottom: 2px solid #e2e2e2 !important;
      padding-bottom: 10px !important;
    }
    table.dataTable tbody tr:hover { background-color: transparent !important; }
  ")),

  div(class = "main-content",

    h1("Arkansas Teacher Merit Pay Calculator",
       style = "color: #00573F; font-family: 'Open Sans', sans-serif; font-weight: 900; margin-bottom: 24px;"),

    fluidRow(

      # Left column: intro text and input form
      column(8,

        p(HTML("The <b>Merit Teacher Incentive Fund (MTIF)</b>, established by the LEARNS Act, provides annual bonuses of up to $10,000 to recognize outstanding Arkansas educators. In 2024–25, over 4,200 teachers received awards totaling $14.24 million. Bonuses are based on student growth performance, subject and geographic shortage designations, advanced licensure, and mentoring. Use this tool to estimate your eligibility — final amounts are calculated by DESE each spring."),
          style = "color: #555; margin-bottom: 20px; line-height: 1.7; font-size: 14px;"),

        div(class = "section-card",
          div(class = "section-label", "Your School"),
          div(style = "width: 100%; max-width: 460px;",
            selectizeInput("district", tags$b("District:"),
                           choices = c("", unique(geographic_data$district_name)),
                           options = list(placeholder = "Select or type to search a district"))
          )
        ),

        conditionalPanel(
          condition = "input.district !== ''",
          div(class = "section-card",
            div(class = "section-label", "Your Teaching"),
            selectizeInput("grade", tags$b("Grade Level:"), choices = "",
                           options = list(placeholder = "Select or type to search a grade"),
                           width = "100%"),
            selectizeInput("subject", tags$b("Subject:"), choices = "",
                           options = list(placeholder = "Select or type to search a subject"),
                           width = "100%")
          )
        ),

        conditionalPanel(
          condition = "input.district !== '' && input.grade !== '' && input.subject !== ''",
          div(class = "section-card",
            div(class = "section-label", "Your Qualifications"),
            radioButtons("designation",
                         HTML('Do you hold a <a href="https://dese.ade.arkansas.gov/Offices/educator-effectiveness/educator-career-continuum-/lead-professional-educator-designation" target="_blank">Lead Professional Educator</a> or <a href="https://dese.ade.arkansas.gov/Offices/educator-effectiveness/educator-career-continuum-/master-professional-educator-designation-pathways" target="_blank">Master Professional Educator</a> designation?'),
                         choices = c("No" = "no", "Yes" = "yes"), inline = TRUE, width = "100%"),
            radioButtons("mentor",
                         HTML('Do you serve as a <a href="https://dese.ade.arkansas.gov/Offices/educator-effectiveness/educator-support--development/mentoring-for-novice-teachers" target="_blank">mentor teacher</a> for a yearlong resident teacher?'),
                         choices = c("No" = "no", "Yes" = "yes"), inline = TRUE, width = "100%")
          )
        ),

        conditionalPanel(
          condition = "input.district !== '' && input.grade !== '' && input.subject !== ''",
          actionButton("submit", "See Merit Pay Eligibility",
                       class = "btn-primary",
                       style = "font-weight: bold; width: 100%; margin-bottom: 28px;")
        )
      ),

      # Right column: reference info as accordion panels
      column(4,
        accordion(
          id = "right_accordion",
          open = FALSE,
          multiple = TRUE,
          accordion_panel(
            "Basic Eligibility Requirements",
            icon = NULL,
            p("To qualify for any merit pay, teachers must:"),
            tags$ul(
              tags$li("Hold a standard or provisional Arkansas teaching license"),
              tags$li("Have at least 3 years of teaching experience"),
              tags$li("Spend 70% or more of contracted time with students"),
              tags$li("Demonstrate positive student growth on state assessments"),
              tags$li("Have no current ethics violations")
            ),
            p(style = "font-size: 13px; color: #aaa; margin-top: 10px; margin-bottom: 0;",
              "Eligible roles include classroom teachers, special education teachers, library media specialists, and school counselors.")
          ),
          accordion_panel(
            "How Bonuses Work",
            icon = NULL,
            p(HTML("Bonuses <b>stack</b> across categories up to the $10,000 cap. For example, a math teacher in a geographic shortage district who ranks in the top 25% for student growth could earn $7,000 ($3,000 + $2,500 + $1,500).")),
            p(HTML("Growth bonuses are tiered by statewide percentile: <b>$3,000</b> (top 25%), <b>$6,000</b> (top 5%), <b>$9,000</b> (top 1%), or <b>$10,000</b> (top 0.5%). DESE determines your tier each spring."))
          ),
          accordion_panel(
            "Resources",
            icon = NULL,
            div(class = "resource-links",
              tags$ul(
                tags$li(tags$a("Merit Teacher Incentive Fund — Arkansas DESE",
                               href = "https://dese.ade.arkansas.gov/Offices/educator-effectiveness/merit-teacher-incentive-fund",
                               target = "_blank")),
                tags$li(tags$a("Merit Pay Eligibility & Amounts — Arkansas DESE",
                               href = "https://dese.ade.arkansas.gov/Offices/educator-effectiveness/merit-teacher-incentive-fund/merit-pay-eligibility--amounts",
                               target = "_blank")),
                tags$li(tags$a("Explaining the 2025 MTIF Program — U of A Office of Education Policy",
                               href = "https://oep.uark.edu/explaining-the-2025-arkansas-merit-teacher-incentive-fund-program/",
                               target = "_blank")),
                tags$li(tags$a("2025 Merit Incentive Business Rules (PDF) — Arkansas DESE",
                               href = "https://dese.ade.arkansas.gov/Files/2025_Merit_Incentive_Business_Rules_6.20.25_EEF.pdf",
                               target = "_blank"))
              )
            )
          )
        )
      )
    )
  ),

  # Results table sits below the two-column layout, full width within 1100px
  div(class = "table-content",
    uiOutput("results_header"),
    DTOutput("bonus_table"),
    uiOutput("bonus_cap_note")
  )
)


server <- function(input, output, session) {

  # Update grade choices once a district is selected
  observeEvent(input$district, {
    if (input$district != "") {
      updateSelectizeInput(session, "grade", choices = c("", unique(grade_level_data$grade)))
    } else {
      updateSelectizeInput(session, "grade", choices = "")
    }
  })

  # Filter subjects based on selected grade
  observeEvent(input$grade, {
    if (input$grade != "") {
      subject_choices <- subject_growth_data %>%
        filter(grade == input$grade) %>%
        pull(subject) %>%
        unique()
      updateSelectizeInput(session, "subject", choices = c("", subject_choices))
    } else {
      updateSelectizeInput(session, "subject", choices = "")
    }
  })

  bonus_results <- reactiveVal(NULL)

  observeEvent(input$submit, {

    if (input$district == "" || input$grade == "" || input$subject == "") {
      showNotification("Please fill in all fields before submitting.", type = "error")
      return()
    }

    geo_row <- geographic_data %>% filter(district_name == input$district)
    selected_data <- subject_growth_data %>% filter(grade == input$grade, subject == input$subject)

    # Pull relevant values from data
    geo_shortage    <- if (nrow(geo_row) > 0) as.integer(geo_row$shortage[1]) else 0
    subject_growth  <- if (nrow(selected_data) > 0) as.integer(selected_data$growth[1]) else 0
    subject_short   <- if (nrow(selected_data) > 0) as.integer(selected_data$shortage[1]) else 0
    subject_label   <- if (nrow(selected_data) > 0) selected_data$label[1] else input$subject
    has_designation <- if (input$designation == "yes") 1 else 0
    is_mentor       <- if (input$mentor == "yes") 1 else 0

    # Fixed bonuses (amounts from 2025 DESE business rules)
    # Geographic shortage: $1,500 | Subject shortage: $2,500
    # Lead/Master designation: $1,500 | Mentor teacher: $3,000
    fixed_total <- (geo_shortage * 1500) + (subject_short * 2500) +
                   (has_designation * 1500) + (is_mentor * 3000)

    # Growth bonus ranges $3,000-$10,000 depending on percentile rank
    # Cap everything at $10,000
    bonus_min <- min(fixed_total + (subject_growth * 3000), 10000)
    bonus_max <- min(fixed_total + (subject_growth * 10000), 10000)

    if (subject_growth == 1) {
      potential_str <- paste0("$", formatC(bonus_min, format = "d", big.mark = ","),
                              " - $", formatC(bonus_max, format = "d", big.mark = ","))
    } else {
      potential_str <- paste0("$", formatC(fixed_total, format = "d", big.mark = ","))
    }

    results_data <- data.frame(
      Category = c(
        "Student Growth Bonus", "Subject Shortage Bonus", "Geographic Shortage Bonus",
        "Lead/Master Designation Bonus", "Mentor Teacher Bonus", "Potential Bonus Amount"
      ),
      Amount = c(
        ifelse(subject_growth == 1, "$3,000 - $10,000", "$0"),
        ifelse(subject_short == 1, "$2,500", "$0"),
        ifelse(geo_shortage == 1, "$1,500", "$0"),
        ifelse(has_designation == 1, "$1,500", "$0"),
        ifelse(is_mentor == 1, "$3,000", "$0"),
        potential_str
      ),
      Description = c(
        if (subject_growth == 1)
          paste0("<b>", input$grade, " ", subject_label, "</b> teachers qualify for a student growth bonus. ",
                 "Bonuses are tiered by statewide percentile: $3,000 (top 25%), $6,000 (top 5%), $9,000 (top 1%), or $10,000 (top 0.5%). ",
                 "Your exact amount depends on your individual 3-year average growth score.")
        else
          paste0("<b>", input$grade, " ", subject_label, "</b> teachers did not meet the threshold for a student growth bonus this year. ",
                 "Eligibility is based on a 3-year average of student growth scores on state assessments."),
        if (subject_short == 1)
          paste0("<b>", subject_label, "</b> is a designated subject shortage area. ",
                 "Shortage subjects include secondary and middle school math, science, foreign language, and special education.")
        else
          paste0("<b>", subject_label, "</b> is not currently a designated subject shortage area. ",
                 "Shortage subjects include secondary and middle school math, science, foreign language, and special education."),
        if (geo_shortage == 1)
          paste0("<b>", input$district, "</b> is in a geographic shortage area, ",
                 "identified based on rates of unlicensed teachers and staff attrition.")
        else
          paste0("<b>", input$district, "</b> is not currently designated as a geographic shortage area."),
        if (has_designation == 1)
          "Your Lead or Master Professional Educator designation qualifies you for this bonus, recognizing your advanced licensure and expertise."
        else
          "You do not currently hold a Lead or Master Professional Educator designation. Earning one would add $1,500 to your eligibility.",
        if (is_mentor == 1)
          paste0("Mentoring a yearlong resident teacher qualifies you for this bonus. ",
                 "Requires a Lead/Master designation and completed DESE coaching training.")
        else
          paste0("You are not currently serving as a mentor to a yearlong resident teacher. ",
                 "This bonus requires a Lead/Master designation and completed DESE coaching training."),
        paste0("Your estimated merit pay eligibility is <b>", potential_str, "</b>. ",
               "Final amounts are calculated by DESE each spring based on your individual growth percentile and district confirmation.")
      ),
      stringsAsFactors = FALSE
    )

    bonus_results(list(table = results_data, max_bonus = bonus_max))
  })

  output$results_header <- renderUI({
    req(bonus_results())
    div(class = "results-header", "Your Merit Pay Eligibility")
  })

  output$bonus_table <- renderDT({
    req(bonus_results())

    datatable(bonus_results()$table,
              escape = FALSE,
              rownames = FALSE,
              selection = "none",
              options = list(
                dom = "t",
                autoWidth = FALSE,
                columnDefs = list(
                  list(width = "200px", targets = 0),
                  list(width = "120px", targets = 1, className = "dt-center"),
                  list(targets = 2)
                ),
                paging = FALSE,
                ordering = FALSE,
                rowCallback = JS(
                  "function(row, data, index) {",
                  "  if (data[0] === 'Potential Bonus Amount') {",
                  "    $('td', row).css({",
                  "      'background-color': '#EAF5EC',",
                  "      'border-top': '2px solid #c3e6cb',",
                  "      'border-bottom': 'none',",
                  "      'font-weight': 'bold',",
                  "      'color': '#1a1a1a',",
                  "      'font-size': '15px'",
                  "    });",
                  "    $(row).find('td:eq(1)').css({'font-size': '18px', 'font-weight': '900', 'color': '#00573F'});",
                  "  }",
                  "}"
                )
              )) %>%
      formatStyle(
        "Amount",
        color = styleEqual(
          c("$0", "$1,500", "$2,500", "$3,000", "$3,000 - $10,000"),
          c("#bbb",  "#2d7a4f", "#2d7a4f", "#2d7a4f", "#2d7a4f")
        ),
        fontWeight = "bold"
      )
  })

  output$bonus_cap_note <- renderUI({
    req(bonus_results())
    if (bonus_results()$max_bonus == 10000) {
      div(class = "bonus-cap-note",
          "Bonus incentives are capped at $10,000 per educator.",
          style = "color: #888; font-size: 13px; margin-top: 8px;")
    }
  })

}

shinyApp(ui = ui, server = server)
