# frozen_string_literal: true

require "rails_helper"
require "rswag/specs"

RSpec.configure do |config|
  config.swagger_strict_schema_validation = true
  config.swagger_root = BopsApi::Engine.root.join("swagger").to_s
  config.swagger_format = :yaml

  config.swagger_docs = {
    "v2/swagger_doc.yaml" => {
      openapi: "3.0.1",
      info: {
        title: "Back-office Planning System",
        version: "v2"
      },
      components: {
        securitySchemes: {
          bearerAuth: {
            type: "http",
            scheme: "bearer"
          }
        },

        schemas: {
          errors: {
            type: "object",
            properties: {
              unauthorized: {
                type: "object",
                properties: {
                  error: {
                    type: "object",
                    properties: {
                      code: {
                        type: "integer",
                        const: 401
                      },
                      message: {
                        type: "string",
                        const: "Unauthorized"
                      }
                    },
                    required: %w[code message]
                  }
                },
                required: %w[error]
              },
              bad_request: {
                type: "object",
                properties: {
                  error: {
                    type: "object",
                    properties: {
                      code: {
                        type: "integer",
                        const: 400
                      },
                      message: {
                        type: "string",
                        const: "Bad Request"
                      },
                      detail: {
                        type: "string"
                      }
                    },
                    required: %w[code message]
                  }
                },
                required: %w[error]
              }
            }
          },
          healthcheck: {
            type: "object",
            properties: {
              message: {
                type: "string",
                const: "OK"
              },
              timestamp: {
                type: "string",
                format: "date-time"
              }
            },
            required: %w[message timestamp]
          },
          planning_application: {
            type: "object",
            properties: {
              data: {
                type: "object",
                properties: {
                  application: {
                    type: "object",
                    properties: {
                      type: {
                        type: "object",
                        properties: {
                          value: {type: "string"},
                          description: {type: "string"}
                        },
                        required: %w[value description]
                      },
                      fee: {
                        type: "object",
                        properties: {
                          calculated: {type: "integer"},
                          payable: {type: "integer"},
                          exemption: {
                            type: "object",
                            properties: {
                              disability: {type: "boolean"},
                              resubmission: {type: "boolean"}
                            }
                          },
                          reduction: {
                            type: "object",
                            properties: {
                              sports: {type: "boolean"},
                              parishCouncil: {type: "boolean"},
                              alternative: {type: "boolean"}
                            }
                          },
                          reference: {
                            type: "object",
                            properties: {
                              govPay: {type: "string"}
                            }
                          }
                        },
                        required: %w[calculated payable exemption reduction reference]
                      },
                      declaration: {
                        type: "object",
                        properties: {
                          accurate: {type: "boolean"},
                          connection: {
                            type: "object",
                            properties: {
                              value: {type: "string"}
                            }
                          }
                        },
                        required: %w[accurate connection]
                      }
                    },
                    required: %w[type fee declaration]
                  },
                  user: {
                    type: "object",
                    properties: {
                      role: {type: "string"}
                    },
                    required: ["role"]
                  },
                  applicant: {
                    type: "object",
                    properties: {
                      type: {type: "string"},
                      name: {
                        type: "object",
                        properties: {
                          first: {type: "string"},
                          last: {type: "string"}
                        },
                        required: %w[first last]
                      },
                      email: {type: "string"},
                      phone: {
                        type: "object",
                        properties: {
                          primary: {type: "string"}
                        },
                        required: ["primary"]
                      },
                      address: {
                        type: "object",
                        properties: {
                          sameAsSiteAddress: {type: "boolean"}
                        },
                        required: ["sameAsSiteAddress"]
                      },
                      siteContact: {
                        type: "object",
                        properties: {
                          role: {type: "string"}
                        },
                        required: ["role"]
                      },
                      interest: {type: "string"},
                      ownership: {
                        type: "object",
                        properties: {
                          certificate: {type: "string"}
                        },
                        required: ["certificate"]
                      },
                      agent: {
                        type: "object",
                        properties: {
                          name: {
                            type: "object",
                            properties: {
                              first: {type: "string"},
                              last: {type: "string"}
                            },
                            required: %w[first last]
                          },
                          email: {type: "string"},
                          phone: {
                            type: "object",
                            properties: {
                              primary: {type: "string"}
                            },
                            required: ["primary"]
                          },
                          address: {
                            type: "object",
                            properties: {
                              line1: {type: "string"},
                              line2: {type: "string"},
                              town: {type: "string"},
                              county: {type: "string"},
                              postcode: {type: "string"},
                              country: {type: "string"}
                            },
                            required: %w[line1 line2 town county postcode country]
                          }
                        },
                        required: %w[name email phone address]
                      }
                    },
                    required: %w[type name email phone address siteContact interest ownership agent]
                  },
                  property: {
                    type: "object",
                    properties: {
                      address: {
                        type: "object",
                        properties: {
                          latitude: {type: "number", format: "float"},
                          longitude: {type: "number", format: "float"},
                          x: {type: "integer"},
                          y: {type: "integer"},
                          title: {type: "string"},
                          singleLine: {type: "string"},
                          source: {type: "string"},
                          uprn: {type: "string"},
                          usrn: {type: "string"},
                          pao: {type: "string"},
                          street: {type: "string"},
                          town: {type: "string"},
                          postcode: {type: "string"}
                        },
                        required: %w[latitude longitude x y title singleLine source uprn usrn pao street town postcode]
                      },
                      boundary: {
                        type: "object",
                        properties: {
                          site: {
                            type: "object",
                            properties: {
                              type: {type: "string"},
                              geometry: {
                                type: "object",
                                properties: {
                                  type: {type: "string"},
                                  coordinates: {
                                    type: "array",
                                    items: {
                                      type: "array",
                                      items: {
                                        type: "array",
                                        items: {
                                          type: "number",
                                          format: "float"
                                        }
                                      }
                                    }
                                  }
                                },
                                required: %w[type coordinates]
                              },
                              properties: {type: "object"}
                            },
                            required: ["type", "geometry"]
                          },
                          area: {
                            type: "object",
                            properties: {
                              hectares: {type: "number", format: "float"},
                              squareMetres: {type: "number", format: "float"}
                            },
                            required: %w[hectares squareMetres]
                          }
                        },
                        required: %w[site area]
                      },
                      planning: {
                        type: "object",
                        properties: {
                          sources: {
                            type: "array",
                            items: {type: "string"}
                          },
                          designations: {
                            type: "array",
                            items: {
                              type: "object",
                              properties: {
                                value: {type: "string"},
                                description: {type: "string"},
                                intersects: {type: "boolean"}
                              },
                              required: %w[value description intersects]
                            }
                          }
                        },
                        required: %w[sources designations]
                      },
                      localAuthorityDistrict: {
                        type: "array",
                        items: {type: "string"}
                      },
                      region: {type: "string"},
                      type: {
                        type: "object",
                        properties: {
                          value: {type: "string"},
                          description: {type: "string"}
                        },
                        required: %w[value description]
                      }
                    },
                    required: %w[address boundary planning localAuthorityDistrict region type]
                  },
                  proposal: {
                    type: "object",
                    properties: {
                      projectType: {
                        type: "array",
                        items: {
                          type: "object",
                          properties: {
                            value: {type: "string"},
                            description: {type: "string"}
                          },
                          required: %w[value description]
                        }
                      },
                      description: {type: "string"},
                      boundary: {
                        type: "object",
                        properties: {},
                        required: %w[...]
                      },
                      date: {
                        type: "object",
                        properties: {
                          start: {type: "string", format: "date"},
                          completion: {type: "string", format: "date"}
                        },
                        required: %w[start completion]
                      },
                      details: {
                        type: "object",
                        properties: {},
                        required: %w[...]
                      }
                    },
                    required: %w[projectType description boundary date details]
                  }
                },
                required: %w[application user applicant property proposal]
              },
              metadata: {
                type: "object",
                properties: {
                  organisation: {type: "string"},
                  id: {type: "string"},
                  source: {type: "string"},
                  service: {
                    type: "object",
                    properties: {
                      flowId: {type: "string"},
                      url: {type: "string"}
                    },
                    required: %w[flowId url]
                  },
                  submittedAt: {type: "string", format: "date-time"},
                  schema: {type: "string"}
                },
                required: %w[organisation id source service submittedAt schema]
              },
              files: {
                type: "array",
                items: {
                  type: "object",
                  properties: {
                    name: {type: "string"},
                    type: {
                      type: "array",
                      items: {
                        type: "object",
                        properties: {
                          value: {type: "string"},
                          description: {type: "string"}
                        },
                        required: %w[value description]
                      }
                    }
                  },
                  required: %w[name type]
                }
              },
              preAssessment: {
                type: "array",
                items: {
                  type: "object",
                  properties: {
                    value: {type: "string"},
                    description: {type: "string"}
                  },
                  required: %w[value description]
                }
              },
              responses: {
                type: "array",
                items: {
                  type: "object",
                  properties: {
                    question: {type: "string"},
                    responses: {
                      type: "array",
                      items: {
                        type: "object",
                        properties: {
                          value: {type: "string"},
                          metadata: {
                            type: "object",
                            properties: {
                              autoAnswered: {type: "boolean", nullable: true},
                              sectionName: {type: "string"},
                              policyRefs: {
                                type: "array",
                                items: {
                                  type: "object",
                                  properties: {
                                    text: {type: "string"},
                                    url: {type: "string"}
                                  },
                                  required: %w[text url]
                                },
                                nullable: true
                              },
                              flags: {
                                type: "array",
                                items: {type: "string"},
                                nullable: true
                              }
                            }
                          }
                        },
                        required: %w[value]
                      }
                    },
                    metadata: {
                      type: "object",
                      properties: {
                        autoAnswered: {type: "boolean", nullable: true},
                        sectionName: {type: "string"}
                      }
                    }
                  },
                  required: %w[question responses metadata]
                }
              }
            },
            required: %w[data metadata files preAssessment responses]
          }
        }
      }
    }
  }
end
