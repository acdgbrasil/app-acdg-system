import { useState, useEffect, useRef } from "react";

// ─── Design Tokens ───────────────────────────────────────────────
const tokens = {
  bg: "#F2E2C4",
  card: "#FAF0E0",
  text: "#261D11",
  textSecondary: "rgba(38,29,17,0.5)",
  borderInactive: "rgba(38,29,17,0.2)",
  divider: "rgba(38,29,17,0.1)",
  primary: "#4F8448",
  error: "#A6290D",
  panel: "#172D48",
  panelText: "#F2E2C4",
  panelDivider: "rgba(242,226,196,0.15)",
};

// ─── Mock Data ───────────────────────────────────────────────────
const FAMILIES = [
  {
    id: "1",
    lastName: "Costa",
    firstName: "Davi",
    fullName: "Davi Costa Faco Franklin de Lima",
    motherName: "Maria Helena Costa",
    diagnosis: "Doença de Fabry",
    birthDate: "18/07/1999",
    cpf: "080.570.183-48",
    status: "Ativo",
    entryDate: "25/05/1999",
    responsible: "Gabriel Aderas",
    cep: "60192-095",
    phone: "(88) 9 8732-1234",
    address: "Rua Doutor Gilberto Studart, 1540",
    members: 4,
  },
  {
    id: "2",
    lastName: "Franklin",
    firstName: "Ana",
    fullName: "Ana Paula Franklin de Souza",
    motherName: "Rosa Franklin de Souza",
    diagnosis: "Síndrome de Marfan",
    birthDate: "03/11/1985",
    cpf: "123.456.789-00",
    status: "Ativo",
    entryDate: "10/03/2020",
    responsible: "Gabriel Aderas",
    cep: "60175-012",
    phone: "(85) 9 9912-4567",
    address: "Av. Santos Dumont, 3200",
    members: 3,
  },
  {
    id: "3",
    lastName: "Aderaldo",
    firstName: "Pedro",
    fullName: "Pedro Henrique Aderaldo",
    motherName: "Francisca Aderaldo",
    diagnosis: "Mucopolissacaridose tipo II",
    birthDate: "22/01/2010",
    cpf: "234.567.890-11",
    status: "Ativo",
    entryDate: "15/08/2021",
    responsible: "Carla Mendes",
    cep: "60811-340",
    phone: "(85) 9 8801-3322",
    address: "Rua Padre Valdevino, 890",
    members: 5,
  },
  {
    id: "4",
    lastName: "Colaço",
    firstName: "Lúcia",
    fullName: "Lúcia Maria Colaço Ribeiro",
    motherName: "Joana Colaço",
    diagnosis: "Fenilcetonúria",
    birthDate: "14/06/1978",
    cpf: "345.678.901-22",
    status: "Inativo",
    entryDate: "01/02/2018",
    responsible: "Gabriel Aderas",
    cep: "60420-100",
    phone: "(85) 3232-4455",
    address: "Rua Torres Câmara, 456",
    members: 2,
  },
  {
    id: "5",
    lastName: "Facó",
    firstName: "Miguel",
    fullName: "Miguel Facó Nogueira",
    motherName: "Tereza Facó",
    diagnosis: "Doença de Gaucher",
    birthDate: "30/09/2015",
    cpf: "456.789.012-33",
    status: "Ativo",
    entryDate: "20/11/2022",
    responsible: "Carla Mendes",
    cep: "60050-001",
    phone: "(85) 9 9988-1122",
    address: "Rua General Sampaio, 120",
    members: 4,
  },
  {
    id: "6",
    lastName: "Soriano",
    firstName: "Beatriz",
    fullName: "Beatriz Soriano Almeida",
    motherName: "Sandra Soriano",
    diagnosis: "Osteogênese Imperfeita",
    birthDate: "05/12/2001",
    cpf: "567.890.123-44",
    status: "Ativo",
    entryDate: "08/06/2023",
    responsible: "Gabriel Aderas",
    cep: "60115-220",
    phone: "(85) 9 8877-6655",
    address: "Av. da Universidade, 2800",
    members: 3,
  },
  {
    id: "7",
    lastName: "Gouveia",
    firstName: "Rafael",
    fullName: "Rafael Gouveia de Melo",
    motherName: "Marta Gouveia",
    diagnosis: "Esclerose Lateral Amiotrófica",
    birthDate: "19/04/1992",
    cpf: "678.901.234-55",
    status: "Ativo",
    entryDate: "12/01/2024",
    responsible: "Carla Mendes",
    cep: "60160-090",
    phone: "(85) 9 7766-5544",
    address: "Rua Barão de Aracati, 670",
    members: 2,
  },
  {
    id: "8",
    lastName: "Benevides",
    firstName: "Clara",
    fullName: "Clara Benevides Martins",
    motherName: "Helena Benevides",
    diagnosis: "Fibrose Cística",
    birthDate: "28/02/2008",
    cpf: "789.012.345-66",
    status: "Ativo",
    entryDate: "30/07/2023",
    responsible: "Gabriel Aderas",
    cep: "60810-780",
    phone: "(85) 9 8844-3322",
    address: "Rua Visconde de Mauá, 345",
    members: 6,
  },
];

const FICHAS = [
  { id: "1", name: "Composição familiar", filled: true },
  { id: "2", name: "Acesso a benefícios eventuais", filled: true },
  { id: "3", name: "Condições de saúde da família", filled: true },
  { id: "4", name: "Convivência familiar e comunitária", filled: true },
  { id: "5", name: "Condições educacionais da família", filled: false },
  { id: "6", name: "Situações de violência e violação de direitos", filled: false },
  { id: "7", name: "Condições de trabalho e rendimento da família", filled: false },
  { id: "8", name: "Especificidades sociais, étnicas ou culturais", filled: false },
  { id: "9", name: "Forma de ingresso e motivo do primeiro atendimento", filled: false },
  { id: "10", name: "Serviços e programas de convivência comunitária", filled: false },
];

// ─── SVG Icons (inline) ──────────────────────────────────────────
const IconMenu = () => (
  <svg width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round">
    <line x1="3" y1="6" x2="21" y2="6" />
    <line x1="3" y1="12" x2="21" y2="12" />
    <line x1="3" y1="18" x2="21" y2="18" />
  </svg>
);
const IconSearch = () => (
  <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round">
    <circle cx="11" cy="11" r="8" />
    <line x1="21" y1="21" x2="16.65" y2="16.65" />
  </svg>
);
const IconClose = () => (
  <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round">
    <line x1="18" y1="6" x2="6" y2="18" />
    <line x1="6" y1="6" x2="18" y2="18" />
  </svg>
);
const IconEdit = () => (
  <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
    <path d="M11 4H4a2 2 0 0 0-2 2v14a2 2 0 0 0 2 2h14a2 2 0 0 0 2-2v-7" />
    <path d="M18.5 2.5a2.121 2.121 0 0 1 3 3L12 15l-4 1 1-4 9.5-9.5z" />
  </svg>
);
const IconForms = () => (
  <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
    <path d="M14 2H6a2 2 0 0 0-2 2v16a2 2 0 0 0 2 2h12a2 2 0 0 0 2-2V8z" />
    <polyline points="14 2 14 8 20 8" />
    <line x1="16" y1="13" x2="8" y2="13" />
    <line x1="16" y1="17" x2="8" y2="17" />
    <polyline points="10 9 9 9 8 9" />
  </svg>
);
const IconChevronRight = () => (
  <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
    <polyline points="9 18 15 12 9 6" />
  </svg>
);
const IconPlus = () => (
  <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round">
    <line x1="12" y1="5" x2="12" y2="19" />
    <line x1="5" y1="12" x2="19" y2="12" />
  </svg>
);
const IconArrowLeft = () => (
  <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
    <line x1="19" y1="12" x2="5" y2="12" />
    <polyline points="12 19 5 12 12 5" />
  </svg>
);
const IconUsers = () => (
  <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
    <path d="M17 21v-2a4 4 0 0 0-4-4H5a4 4 0 0 0-4 4v2" />
    <circle cx="9" cy="7" r="4" />
    <path d="M23 21v-2a4 4 0 0 0-3-3.87" />
    <path d="M16 3.13a4 4 0 0 1 0 7.75" />
  </svg>
);

// ─── Sub-components ──────────────────────────────────────────────

function StatusBadge({ status }) {
  const isActive = status === "Ativo";
  return (
    <span
      style={{
        display: "inline-flex",
        alignItems: "center",
        gap: 6,
        fontFamily: "'Satoshi', sans-serif",
        fontWeight: 500,
        fontSize: 14,
        color: isActive ? tokens.primary : tokens.error,
      }}
    >
      <span
        style={{
          width: 8,
          height: 8,
          borderRadius: "50%",
          background: isActive ? tokens.primary : tokens.error,
        }}
      />
      {status}
    </span>
  );
}

function CircleButton({ onClick, children, variant = "default", title }) {
  const [hovered, setHovered] = useState(false);
  const isClose = variant === "close";
  return (
    <button
      onClick={onClick}
      onMouseEnter={() => setHovered(true)}
      onMouseLeave={() => setHovered(false)}
      title={title}
      style={{
        width: 40,
        height: 40,
        borderRadius: "50%",
        border: `1.5px solid ${isClose ? "rgba(242,226,196,0.4)" : "rgba(242,226,196,0.25)"}`,
        background: hovered
          ? isClose
            ? "rgba(166,41,13,0.2)"
            : "rgba(242,226,196,0.1)"
          : "transparent",
        color: isClose ? tokens.error : tokens.panelText,
        display: "flex",
        alignItems: "center",
        justifyContent: "center",
        cursor: "pointer",
        transition: "all 0.2s ease",
      }}
    >
      {children}
    </button>
  );
}

function DataField({ label, value }) {
  return (
    <div style={{ minWidth: 0 }}>
      <div
        style={{
          fontFamily: "'Satoshi', sans-serif",
          fontWeight: 700,
          fontSize: 13,
          color: "rgba(242,226,196,0.5)",
          textTransform: "uppercase",
          letterSpacing: "0.05em",
          marginBottom: 4,
        }}
      >
        {label}
      </div>
      <div
        style={{
          fontFamily: "'Playfair Display', serif",
          fontWeight: 400,
          fontSize: 16,
          color: tokens.panelText,
          overflow: "hidden",
          textOverflow: "ellipsis",
          whiteSpace: "nowrap",
        }}
      >
        {value || "—"}
      </div>
    </div>
  );
}

// ─── Detail Panel: Dados ─────────────────────────────────────────

function PanelDados({ family, onClose, onShowFichas }) {
  return (
    <div style={{ padding: "48px 48px 32px", height: "100%", overflowY: "auto" }}>
      {/* Header */}
      <div style={{ display: "flex", justifyContent: "space-between", alignItems: "flex-start", marginBottom: 40 }}>
        <div>
          <h2
            style={{
              fontFamily: "'Satoshi', sans-serif",
              fontWeight: 700,
              fontSize: 48,
              color: tokens.panelText,
              margin: 0,
              lineHeight: 1,
              letterSpacing: "-0.02em",
            }}
          >
            Dados
          </h2>
          <div style={{ marginTop: 8 }}>
            <StatusBadge status={family.status} />
          </div>
        </div>
        <div style={{ display: "flex", gap: 8 }}>
          <CircleButton onClick={onShowFichas} title="Fichas">
            <IconForms />
          </CircleButton>
          <CircleButton title="Editar">
            <IconEdit />
          </CircleButton>
          <CircleButton onClick={onClose} variant="close" title="Fechar">
            <IconClose />
          </CircleButton>
        </div>
      </div>

      {/* Data Grid */}
      <div style={{ display: "flex", flexDirection: "column", gap: 28 }}>
        <DataField label="Nome completo" value={family.fullName} />
        <DataField label="Nome da mãe" value={family.motherName} />

        <div style={{ borderTop: `1px solid ${tokens.panelDivider}`, paddingTop: 24 }}>
          <DataField label="Diagnóstico" value={family.diagnosis} />
        </div>

        <div style={{ display: "grid", gridTemplateColumns: "1fr 1fr", gap: "24px 40px" }}>
          <DataField label="Data de nascimento" value={family.birthDate} />
          <DataField label="CPF" value={family.cpf} />
          <DataField label="Data de ingresso" value={family.entryDate} />
          <DataField label="Tec. responsável" value={family.responsible} />
          <DataField label="CEP" value={family.cep} />
          <DataField label="Telefone" value={family.phone} />
        </div>

        <div style={{ borderTop: `1px solid ${tokens.panelDivider}`, paddingTop: 24 }}>
          <DataField label="Endereço" value={family.address} />
        </div>
      </div>
    </div>
  );
}

// ─── Detail Panel: Fichas ────────────────────────────────────────

function PanelFichas({ family, onClose, onBack }) {
  return (
    <div style={{ padding: "48px 48px 32px", height: "100%", overflowY: "auto" }}>
      {/* Header */}
      <div style={{ display: "flex", justifyContent: "space-between", alignItems: "flex-start", marginBottom: 40 }}>
        <h2
          style={{
            fontFamily: "'Satoshi', sans-serif",
            fontWeight: 700,
            fontSize: 48,
            color: tokens.panelText,
            margin: 0,
            lineHeight: 1,
            letterSpacing: "-0.02em",
          }}
        >
          Fichas
        </h2>
        <div style={{ display: "flex", gap: 8 }}>
          <CircleButton onClick={onBack} title="Voltar">
            <IconArrowLeft />
          </CircleButton>
          <CircleButton onClick={onClose} variant="close" title="Fechar">
            <IconClose />
          </CircleButton>
        </div>
      </div>

      {/* Subtitle */}
      <p
        style={{
          fontFamily: "'Playfair Display', serif",
          fontSize: 15,
          color: "rgba(242,226,196,0.45)",
          margin: "0 0 24px 0",
          fontStyle: "italic",
        }}
      >
        Família {family.lastName} — {FICHAS.filter((f) => f.filled).length} de {FICHAS.length} preenchidas
      </p>

      {/* Fichas List */}
      <div style={{ display: "flex", flexDirection: "column" }}>
        {FICHAS.map((ficha, i) => (
          <FichaRow key={ficha.id} ficha={ficha} isLast={i === FICHAS.length - 1} />
        ))}
      </div>
    </div>
  );
}

function FichaRow({ ficha, isLast }) {
  const [hovered, setHovered] = useState(false);
  return (
    <button
      onMouseEnter={() => setHovered(true)}
      onMouseLeave={() => setHovered(false)}
      style={{
        display: "flex",
        alignItems: "center",
        justifyContent: "space-between",
        padding: "18px 0",
        borderBottom: isLast ? "none" : `1px solid ${tokens.panelDivider}`,
        background: "transparent",
        border: "none",
        borderBottomStyle: isLast ? "none" : "solid",
        borderBottomWidth: isLast ? 0 : 1,
        borderBottomColor: tokens.panelDivider,
        cursor: "pointer",
        textAlign: "left",
        width: "100%",
        transition: "all 0.15s ease",
        opacity: hovered ? 1 : ficha.filled ? 0.9 : 0.5,
      }}
    >
      <span
        style={{
          fontFamily: "'Satoshi', sans-serif",
          fontWeight: 500,
          fontSize: 16,
          color: tokens.panelText,
          flex: 1,
          paddingRight: 16,
        }}
      >
        {ficha.name}
      </span>
      <span style={{ color: tokens.panelText, flexShrink: 0, opacity: 0.6 }}>
        {ficha.filled ? <IconChevronRight /> : <IconPlus />}
      </span>
    </button>
  );
}

// ─── Family List Item ────────────────────────────────────────────

function FamilyItem({ family, isSelected, isAnySelected, onClick }) {
  const [hovered, setHovered] = useState(false);
  const isHighlighted = isSelected || (hovered && !isAnySelected) || (hovered && isSelected);
  const isFaded = isAnySelected && !isSelected && !hovered;

  return (
    <button
      onClick={onClick}
      onMouseEnter={() => setHovered(true)}
      onMouseLeave={() => setHovered(false)}
      style={{
        display: "flex",
        alignItems: "baseline",
        gap: 12,
        padding: "10px 0",
        background: "transparent",
        border: "none",
        cursor: "pointer",
        width: "100%",
        textAlign: "left",
        transition: "all 0.25s ease",
      }}
    >
      <span
        style={{
          fontFamily: "'Satoshi', sans-serif",
          fontWeight: isHighlighted ? 700 : 500,
          fontSize: 40,
          lineHeight: 1.2,
          color: isFaded ? tokens.textSecondary : tokens.text,
          transition: "all 0.25s ease",
        }}
      >
        {family.lastName}
      </span>
      <span
        style={{
          fontFamily: "'Playfair Display', serif",
          fontStyle: "italic",
          fontWeight: 300,
          fontSize: 16,
          color: tokens.textSecondary,
          opacity: isHighlighted ? 1 : 0,
          transform: isHighlighted ? "translateX(0)" : "translateX(-8px)",
          transition: "all 0.3s ease",
        }}
      >
        {family.firstName} · {family.members} membros
      </span>
    </button>
  );
}

// ─── Main App ────────────────────────────────────────────────────

export default function ConectaRarosHome() {
  const [selectedId, setSelectedId] = useState(null);
  const [panelView, setPanelView] = useState("dados"); // "dados" | "fichas"
  const [searchQuery, setSearchQuery] = useState("");
  const [activeTab, setActiveTab] = useState("familias");
  const [panelVisible, setPanelVisible] = useState(false);
  const searchRef = useRef(null);

  const selectedFamily = FAMILIES.find((f) => f.id === selectedId);

  const filteredFamilies = FAMILIES.filter((f) => {
    const q = searchQuery.toLowerCase();
    return (
      f.lastName.toLowerCase().includes(q) ||
      f.firstName.toLowerCase().includes(q) ||
      f.fullName.toLowerCase().includes(q)
    );
  });

  function handleSelect(id) {
    if (selectedId === id) {
      handleClosePanel();
    } else {
      setSelectedId(id);
      setPanelView("dados");
      setPanelVisible(true);
    }
  }

  function handleClosePanel() {
    setPanelVisible(false);
    setTimeout(() => {
      setSelectedId(null);
      setPanelView("dados");
    }, 350);
  }

  useEffect(() => {
    function handleKey(e) {
      if (e.key === "Escape") handleClosePanel();
    }
    window.addEventListener("keydown", handleKey);
    return () => window.removeEventListener("keydown", handleKey);
  }, []);

  return (
    <div
      style={{
        width: "100%",
        height: "100vh",
        background: tokens.bg,
        display: "flex",
        flexDirection: "column",
        overflow: "hidden",
        fontFamily: "'Satoshi', sans-serif",
        position: "relative",
      }}
    >
      {/* ── Google Fonts ── */}
      <link
        href="https://fonts.googleapis.com/css2?family=Playfair+Display:ital,wght@0,400;0,500;0,700;1,300;1,400;1,500&family=DM+Sans:wght@400;500;700&display=swap"
        rel="stylesheet"
      />
      <style>{`
        @font-face {
          font-family: 'Satoshi';
          src: url('https://api.fontshare.com/v2/css?f[]=satoshi@700,500,400&display=swap');
        }
        @import url('https://api.fontshare.com/v2/css?f[]=satoshi@700,500,400&display=swap');

        * { box-sizing: border-box; margin: 0; padding: 0; }
        ::-webkit-scrollbar { width: 4px; }
        ::-webkit-scrollbar-track { background: transparent; }
        ::-webkit-scrollbar-thumb { background: rgba(38,29,17,0.15); border-radius: 4px; }
        ::-webkit-scrollbar-thumb:hover { background: rgba(38,29,17,0.3); }

        @keyframes slideIn {
          from { transform: translateX(100%); }
          to { transform: translateX(0); }
        }
        @keyframes slideOut {
          from { transform: translateX(0); }
          to { transform: translateX(100%); }
        }
        @keyframes fadeIn {
          from { opacity: 0; }
          to { opacity: 1; }
        }
      `}</style>

      {/* ── Top Bar ── */}
      <header
        style={{
          display: "flex",
          alignItems: "center",
          padding: "24px 48px",
          gap: 32,
          flexShrink: 0,
          position: "relative",
          zIndex: 10,
        }}
      >
        <button
          style={{
            background: "none",
            border: "none",
            cursor: "pointer",
            color: tokens.text,
            padding: 8,
            display: "flex",
            alignItems: "center",
          }}
          title="Menu"
        >
          <IconMenu />
        </button>

        <nav style={{ display: "flex", gap: 4 }}>
          {[
            { key: "familias", label: "Famílias" },
            { key: "cadastro", label: "Cadastro" },
          ].map((tab) => (
            <button
              key={tab.key}
              onClick={() => setActiveTab(tab.key)}
              style={{
                background: activeTab === tab.key ? "rgba(38,29,17,0.08)" : "transparent",
                border: "none",
                borderRadius: 100,
                padding: "8px 20px",
                fontFamily: "'Satoshi', sans-serif",
                fontWeight: activeTab === tab.key ? 700 : 500,
                fontSize: 15,
                color: tokens.text,
                cursor: "pointer",
                transition: "all 0.2s ease",
              }}
            >
              {tab.label}
            </button>
          ))}
        </nav>

        <div style={{ flex: 1 }} />

        <span
          style={{
            fontFamily: "'Playfair Display', serif",
            fontStyle: "italic",
            fontWeight: 300,
            fontSize: 14,
            color: tokens.textSecondary,
          }}
        >
          {FAMILIES.length} famílias cadastradas
        </span>
      </header>

      {/* ── Content ── */}
      <div style={{ display: "flex", flex: 1, overflow: "hidden", position: "relative" }}>
        {/* ── Left: List ── */}
        <div
          style={{
            flex: 1,
            display: "flex",
            flexDirection: "column",
            padding: "0 48px 32px",
            overflow: "hidden",
            transition: "all 0.35s cubic-bezier(0.4, 0, 0.2, 1)",
          }}
        >
          {/* Search */}
          <div
            style={{
              display: "flex",
              alignItems: "center",
              gap: 12,
              padding: "12px 20px",
              borderRadius: 100,
              border: `1.5px solid ${tokens.borderInactive}`,
              background: "rgba(250,240,224,0.5)",
              marginBottom: 24,
              maxWidth: 420,
              transition: "border-color 0.2s ease",
            }}
          >
            <span style={{ color: tokens.textSecondary, display: "flex" }}>
              <IconSearch />
            </span>
            <input
              ref={searchRef}
              type="text"
              placeholder="Pesquisar família..."
              value={searchQuery}
              onChange={(e) => setSearchQuery(e.target.value)}
              style={{
                flex: 1,
                border: "none",
                background: "transparent",
                fontFamily: "'Playfair Display', serif",
                fontStyle: "italic",
                fontWeight: 300,
                fontSize: 18,
                color: tokens.text,
                outline: "none",
              }}
            />
            {searchQuery && (
              <button
                onClick={() => {
                  setSearchQuery("");
                  searchRef.current?.focus();
                }}
                style={{
                  background: "none",
                  border: "none",
                  cursor: "pointer",
                  color: tokens.textSecondary,
                  display: "flex",
                  padding: 2,
                }}
              >
                <IconClose />
              </button>
            )}
          </div>

          {/* Family List */}
          <div
            style={{
              flex: 1,
              overflowY: "auto",
              paddingRight: 16,
            }}
          >
            {filteredFamilies.length === 0 ? (
              <div
                style={{
                  display: "flex",
                  flexDirection: "column",
                  alignItems: "center",
                  justifyContent: "center",
                  height: "60%",
                  gap: 12,
                }}
              >
                <span style={{ fontSize: 48, opacity: 0.2 }}>🔍</span>
                <p
                  style={{
                    fontFamily: "'Playfair Display', serif",
                    fontStyle: "italic",
                    fontSize: 18,
                    color: tokens.textSecondary,
                  }}
                >
                  Nenhuma família encontrada
                </p>
              </div>
            ) : (
              filteredFamilies.map((family) => (
                <FamilyItem
                  key={family.id}
                  family={family}
                  isSelected={selectedId === family.id}
                  isAnySelected={!!selectedId}
                  onClick={() => handleSelect(family.id)}
                />
              ))
            )}
          </div>
        </div>

        {/* ── Right: Detail Panel ── */}
        {selectedId && selectedFamily && (
          <>
            {/* Overlay */}
            <div
              onClick={handleClosePanel}
              style={{
                position: "absolute",
                inset: 0,
                background: "rgba(38,29,17,0.05)",
                zIndex: 5,
                animation: panelVisible ? "fadeIn 0.3s ease forwards" : undefined,
                opacity: panelVisible ? 1 : 0,
                transition: "opacity 0.3s ease",
                pointerEvents: panelVisible ? "auto" : "none",
              }}
            />
            {/* Panel */}
            <div
              style={{
                position: "absolute",
                right: 0,
                top: 0,
                bottom: 0,
                width: "min(56%, 720px)",
                background: tokens.panel,
                zIndex: 10,
                borderRadius: "24px 0 0 24px",
                overflow: "hidden",
                boxShadow: "-8px 0 40px rgba(23,45,72,0.3)",
                animation: panelVisible
                  ? "slideIn 0.35s cubic-bezier(0.4, 0, 0.2, 1) forwards"
                  : "slideOut 0.35s cubic-bezier(0.4, 0, 0.2, 1) forwards",
              }}
            >
              {panelView === "dados" ? (
                <PanelDados
                  family={selectedFamily}
                  onClose={handleClosePanel}
                  onShowFichas={() => setPanelView("fichas")}
                />
              ) : (
                <PanelFichas
                  family={selectedFamily}
                  onClose={handleClosePanel}
                  onBack={() => setPanelView("dados")}
                />
              )}
            </div>
          </>
        )}
      </div>

      {/* ── FAB: Novo Cadastro ── */}
      <button
        onClick={() => setActiveTab("cadastro")}
        style={{
          position: "fixed",
          bottom: 32,
          right: 32,
          display: "flex",
          alignItems: "center",
          gap: 10,
          padding: "16px 28px",
          borderRadius: 100,
          background: tokens.primary,
          color: "#fff",
          border: "none",
          cursor: "pointer",
          fontFamily: "'Playfair Display', serif",
          fontStyle: "italic",
          fontWeight: 500,
          fontSize: 16,
          boxShadow: "0 4px 24px rgba(79,132,72,0.35)",
          transition: "all 0.2s ease",
          zIndex: 20,
        }}
        onMouseEnter={(e) => {
          e.currentTarget.style.transform = "translateY(-2px)";
          e.currentTarget.style.boxShadow = "0 6px 32px rgba(79,132,72,0.45)";
        }}
        onMouseLeave={(e) => {
          e.currentTarget.style.transform = "translateY(0)";
          e.currentTarget.style.boxShadow = "0 4px 24px rgba(79,132,72,0.35)";
        }}
      >
        <IconPlus />
        Novo cadastro
      </button>
    </div>
  );
}