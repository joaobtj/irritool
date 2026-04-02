#
library(shiny)
# library(irritool) # Remove the comment tag when running inside the loaded package environment

# 1. User Interface (UI)
ui <- fluidPage(

  # Set the title of the application
  titlePanel("Dimensionamento Hidráulico - Perda de Carga"),

  sidebarLayout(

    # Input panel
    sidebarPanel(
      h4("1. Parâmetros da Tubulação"),
      numericInput("diameter", "Diâmetro interno (m):", value = 0.05, min = 0.001, step = 0.01),
      numericInput("length", "Comprimento da linha (m):", value = 100, min = 0.1, step = 10),

      h4("2. Dados do Escoamento"),
      numericInput("flow_rate", "Vazão da água:", value = 10, min = 0.01, step = 1),
      selectInput("flow_unit", "Unidade de medida:",
                  choices = c("m³/h" = "m3/h", "L/h" = "l/h", "L/s" = "l/s", "m³/s" = "m3/s")),

      h4("3. Modelo Matemático"),
      selectInput("method", "Equação para cálculo de atrito:",
                  choices = c("Darcy-Weisbach (Colebrook)" = "darcy_colebrook",
                              "Hazen-Williams" = "hazen_williams",
                              "Flamant" = "flamant",
                              "Swamee-Jain" = "swamee_jain",
                              "Blasius" = "blasius",
                              "Haaland" = "haaland",
                              "Churchill" = "churchill",
                              "Chen" = "chen")),

      # Conditional input: Displayed only for Hazen-Williams
      conditionalPanel(
        condition = "input.method == 'hazen_williams'",
        numericInput("hazen_coef", "Coeficiente C (Hazen-Williams):", value = 140, min = 50, max = 150)
      ),

      # Conditional input: Displayed only for Flamant
      conditionalPanel(
        condition = "input.method == 'flamant'",
        numericInput("flamant_coef", "Coeficiente b (Flamant):", value = 0.000135, step = 0.00001)
      ),

      # Conditional input: Displayed for all Darcy-Weisbach based methods
      conditionalPanel(
        condition = "input.method != 'hazen_williams' && input.method != 'flamant'",
        numericInput("roughness", "Rugosidade Absoluta (m):", value = 1.5e-6, step = 1e-6)
      )
    ),

    # Output panel
    mainPanel(
      h3("Resultado Analítico"),

      # A distinct well panel to highlight the final result
      wellPanel(
        h4("Perda de Carga Total (hf):"),
        h1(textOutput("hf_result"), style = "color: #005A8D; font-weight: bold;")
      ),

      # Additional didactic information
      br(),
      p("Este cálculo utiliza o motor matemático rigoroso em R, garantindo a mesma precisão adotada em rotinas avançadas de simulação e softwares de engenharia.")
    )
  )
)

# 2. Server Logic
server <- function(input, output) {

  # Reactive expression to calculate head loss
  output$hf_result <- renderText({

    # Require essential inputs to prevent premature evaluation crashes
    req(input$diameter, input$flow_rate, input$length)

    # Call the core package function
    # Note: Use tryCatch in production to gracefully handle extreme out-of-bounds parameters
    hf <- calc_head_loss(
      diameter = input$diameter,
      flow_rate = input$flow_rate,
      flow_unit = input$flow_unit,
      length = input$length,
      method = input$method,
      roughness = input$roughness,
      hazen_coef = input$hazen_coef,
      flamant_coef = input$flamant_coef
    )

    # Format output to 4 decimal places with the 'mca' unit
    paste(format(round(hf, 4), nsmall = 4), "mca")
  })
}

# 3. Run Application
shinyApp(ui = ui, server = server)
